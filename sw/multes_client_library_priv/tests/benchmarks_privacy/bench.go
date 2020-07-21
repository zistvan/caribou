package main

import (
	"bufio"
	"encoding/csv"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	"multes_client_library_priv/rotpert"
	"os"
	"strconv"
	"strings"
	"time"
)

func writeCsv(data [][]float64, columnNames []string, outPath string) {
	if len(data) == 0 {
		return
	}

	//fmt.Printf("*%d*%d*\n", len(data), len(data[0]))

	stringData := make([][]string, len(data[0])+1)
	for i := 0; i < len(data[0])+1; i++ {
		stringData[i] = make([]string, len(data))
	}
	for i := 0; i < len(data); i++ {
		stringData[0][i] = columnNames[i]
		for j := 1; j <= len(data[0]); j++ {
			stringData[j][i] = fmt.Sprintf("%f", data[i][j-1])
		}
	}
	pfout, err := os.Create(outPath)
	if err != nil {
		panic(err)
	}
	csvWriter := csv.NewWriter(pfout)
	err = csvWriter.WriteAll(stringData)
	if err != nil {
		panic(err)
	}
	csvWriter.Flush()
}

func storeRot(matrix [][]float64, columnPermutation []int, file string) {
	stringData := strconv.Itoa(len(matrix)) + " " + strconv.Itoa(len(matrix[0])) + "\n"
	for i := 0; i < len(matrix); i++ {
		for j := 0; j < len(matrix[0]); j++ {
			stringData += fmt.Sprintf("%f ", matrix[i][j])
		}
		stringData += "\n"
	}
	stringData += strconv.Itoa(len(columnPermutation)) + "\n"
	for i := 0; i < len(columnPermutation); i++ {
		stringData += fmt.Sprintf("%d ", columnPermutation[i])
	}

	err := ioutil.WriteFile(".temp_"+file, []byte(stringData), 0644)
	if err != nil {
		log.Fatalf("Error WriteFile: %v", err)
	}
}

func getRot(file string) ([][]float64, []int) {
	fp, err := os.Open(".temp_" + file)
	if err != nil {
		log.Fatalf("Error Open: %v", err)
	}

	s := bufio.NewScanner(fp)
	s.Split(bufio.ScanWords)

	s.Scan()
	rowsNo, err := strconv.Atoi(s.Text())
	if err != nil {
		log.Fatalf("Error Atoi: %v", err)
	}

	s.Scan()
	colsNo, err := strconv.Atoi(s.Text())
	if err != nil {
		log.Fatalf("Error Atoi: %v", err)
	}

	matrix := make([][]float64, rowsNo)
	for i := 0; i < rowsNo; i++ {
		matrix[i] = make([]float64, colsNo)
		for j := 0; j < colsNo; j++ {
			s.Scan()
			matrix[i][j], err = strconv.ParseFloat(s.Text(), 64)
			if err != nil {
				log.Fatalf("Error ParseFloat: %v", err)
			}
		}
	}

	s.Scan()
	columnPermutationLength, err := strconv.Atoi(s.Text())
	if err != nil {
		log.Fatalf("Error Atoi: %v", err)
	}

	columnPermutation := make([]int, columnPermutationLength)
	for i := 0; i < columnPermutationLength; i++ {
		s.Scan()
		columnPermutation[i], err = strconv.Atoi(s.Text())
		if err != nil {
			log.Fatalf("Error Atoi: %v", err)
		}
	}

	return matrix, columnPermutation
}

func main() {
	var (
		err         error
		hostAddress string
		inFilePath  string
		keyString   string
		repeatsNo   int
		bulkSize    int
		shouldWrite bool
		mode        string
		shouldPrint bool
	)

	flag.StringVar(&hostAddress, "h", "localhost:11211", "The address of the server (host:port).")
	flag.StringVar(&inFilePath, "f", "diabetes.parquet", "Path to the .parquet input file.")
	flag.StringVar(&keyString, "k", "key", "Key for KVS addressing.")
	flag.IntVar(&bulkSize, "b", 36, "Server request bulk size (should be multiple of 3).")
	flag.IntVar(&repeatsNo, "r", 1, "No of repeats for reading dataset.")
	flag.BoolVar(&shouldWrite, "w", false, "Set true if result files should be written.")
	flag.StringVar(&mode, "m", "p", "Mode: s = store file; p = perturb in storage; c = perturb on cpu; n = get nonperturbed.")
	flag.BoolVar(&shouldPrint, "p", true, "Set false in order to not print timing info.")
	flag.Parse()

	inFilePathWithoutExtension := inFilePath[:strings.IndexByte(inFilePath, '.')]

	key := []byte(keyString)

	var schema parquet.Schema
	if strings.Contains(inFilePath, "banknote") {
		schema = parquet.BanknoteData{}
	} else if strings.Contains(inFilePath, "diabetes") {
		schema = parquet.PimaIndiansDiabetesData{}
	} else if strings.Contains(inFilePath, "bank") {
		schema = parquet.BankClientMarketingData{}
	}

	columnNames := schema.GetColumnNames()

	client := ops.NewClient(hostAddress)
	err = client.Connect()
	if err != nil {
		log.Fatalf("Error Connect: %v\n", err)
	}
	defer client.Disconnect()

	p, err := parquet.NewProcessor(client, schema)
	if err != nil {
		log.Fatalf("Error NewProcessor: %v\n", err)
	}

	p.SetOutputColumn(len(columnNames) - 1)

	switch mode {
	case "s":
		err = p.StoreFile(key, inFilePath)
		if err != nil {
			log.Fatalf("Error StoreFile: %v\n", err)
		}

		err = p.SetRotationMatrix(inFilePath)
		if err != nil {
			log.Fatalf("Error SetRotationMatrix: %v\n", err)
		}

		storeRot(p.RotationMatrix, p.ColumnPermutation, inFilePathWithoutExtension)
	case "p":
		p.RotationMatrix, p.ColumnPermutation = getRot(inFilePathWithoutExtension)

		var perturbedData [][]float64

		start1 := time.Now()
		for i := 0; i < repeatsNo; i++ {
			perturbedData, err = p.GetPerturbedRows(key, bulkSize)
			if err != nil {
				log.Fatalf("Error GetPerturbedRows: %s\n", err)
			}
		}
		t1 := float64(time.Since(start1).Microseconds()) / 1e6
		if shouldPrint {
			fmt.Printf("Seconds for perturbation on FPGA = %f\n", t1)
		}

		if shouldWrite {
			outFilePath := fmt.Sprintf("%s_pert.csv", inFilePathWithoutExtension)
			writeCsv(perturbedData, columnNames, outFilePath)
		}
	case "c":
		p.RotationMatrix, p.ColumnPermutation = getRot(inFilePathWithoutExtension)

		for i := 0; i < len(columnNames); i++ {
			p.SetOutputColumn(i)
		}

		var rotatedData [][]float64

		start2 := time.Now()
		for i := 0; i < repeatsNo; i++ {
			originalData, err := p.GetPerturbedRows(key, bulkSize)
			if err != nil {
				log.Fatalf("Error GetPerturbedRows: %s\n", err)
			}

			rotatedData = make([][]float64, len(originalData))
			for i := range rotatedData {
				rotatedData[i] = make([]float64, len(originalData[0]))
			}

			var rotated []float64
			for i := 0; i < len(p.ColumnPermutation); i += 3 {
				for j := 0; j < len(originalData[0]); j++ {
					rotated = rotpert.RotateVector3D(p.RotationMatrix, []float64{originalData[p.ColumnPermutation[i]][j],
						originalData[p.ColumnPermutation[i+1]][j], originalData[p.ColumnPermutation[i+2]][j]})
					for k := 0; k < 3; k++ {
						if i+k < len(originalData)-1 {
							rotatedData[p.ColumnPermutation[i+k]][j] = rotated[k]
						}
					}
				}
			}
			for i := 0; i < len(originalData[0]); i++ {
				rotatedData[len(originalData)-1][i] = originalData[len(originalData)-1][i]
			}
		}
		t2 := float64(time.Since(start2).Microseconds()) / 1e6
		if shouldPrint {
			fmt.Printf("Seconds for perturbation on CPU = %f\n", t2)
		}

		if shouldWrite {
			outFilePath := fmt.Sprintf("%s_cpu.csv", inFilePathWithoutExtension)
			writeCsv(rotatedData, columnNames, outFilePath)
		}
	case "n":
		p.RotationMatrix, p.ColumnPermutation = getRot(inFilePathWithoutExtension)

		for i := 0; i < len(columnNames); i++ {
			p.SetOutputColumn(i)
		}

		var d [][]float64

		start3 := time.Now()
		for i := 0; i < repeatsNo; i++ {
			d, err = p.GetPerturbedRows(key, bulkSize)
			if err != nil {
				log.Fatalf("Error GetPerturbedRows: %s\n", err)
			}
		}
		t3 := float64(time.Since(start3).Microseconds()) / 1e6
		if shouldPrint {
			fmt.Printf("Seconds for nonperturbed read = %f\n", t3)
		}

		if shouldWrite {
			outFilePath := fmt.Sprintf("%s_orig.csv", inFilePathWithoutExtension)
			writeCsv(d, columnNames, outFilePath)
		}
	default:
		log.Fatalf("Invalid mode!")
	}
}
