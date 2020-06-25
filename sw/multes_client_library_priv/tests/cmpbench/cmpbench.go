package main

import (
	"bytes"
	"encoding/binary"
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	"multes_client_library_priv/rotpert"
	"os"
	"strconv"
	"strings"
	"time"
)

var columns = []string{"Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI", "DiabetesPedigreeFunction", "Age", "Outcome"}
var transformColumns = []string{"Pregnancies",
	"Glucose",
	"BloodPressure",
	"SkinThickness",
	"Insulin",
	"BMI",
	"DiabetesPedigreeFunction",
	"Age"}
var outputColumns = []string{"Outcome"}

var schema parquet.PimaIndiansDiabetesData
var matrix = []float64{0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3}

func main() {
	var (
		err         error
		inFilePath  string
		hostAddress string
	)

	flag.StringVar(&hostAddress, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&inFilePath, "f", "diabetes.parquet", "Path to the .parquet input file.")
	flag.Parse()

	inFilePathWithoutExtension := inFilePath[:strings.IndexByte(inFilePath, '.')]
	csvFilePath := fmt.Sprintf("%s.csv", inFilePathWithoutExtension)
	csvOut1FilePath := fmt.Sprintf("%s_t1.csv", inFilePathWithoutExtension)
	csvOut2FilePath := fmt.Sprintf("%s_t2.csv", inFilePathWithoutExtension)

	pf, err := os.Open(csvFilePath)
	if err != nil {
		panic(err)
	}
	reader := csv.NewReader(pf)
	records, err := reader.ReadAll()
	if err != nil {
		panic(err)
	}
	pf.Close()
	transformColumnsMap := make(map[int]int)
	outputColumnsMap := make(map[int]int)
	for i, columnTitle := range records[0] {
		transformColumnsMap[i] = -1
		for j, transformColumn := range transformColumns {
			if columnTitle == transformColumn {
				transformColumnsMap[i] = j
			}
		}
		for j, outputColumn := range outputColumns {
			if columnTitle == outputColumn {
				outputColumnsMap[j] = i
			}
		}
	}
	var data [][]float64
	for _, record := range records[1:] {
		dataRecord := make([]float64, len(transformColumns))
		for i, elem := range record {
			if transformColumnsMap[i] >= 0 {
				dataRecord[transformColumnsMap[i]], err = strconv.ParseFloat(elem, 64)
				if err != nil {
					panic(err)
				}
			}
		}
		data = append(data, dataRecord)
	}
	normalizedData := rotpert.Normalize(data)
	columnPermutation := rotpert.RandomPermutation(len(data[0]))
	rotationMatrix := rotpert.GetBestRotationMatrix(normalizedData, columnPermutation)
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			matrix[3*i+j] = rotationMatrix[j][i]
		}
	}

	// FPGA
	client := ops.NewClient(hostAddress)

	err = client.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer client.Disconnect()

	p, err := parquet.NewProcessor(client, schema)
	if err != nil {
		log.Fatalf("Error new processor: %s\n", err)
	}

	key := []byte("ttt")

	err = p.StoreFile(key, inFilePath)
	if err != nil {
		log.Fatalf("Error store file: %s\n", err)
	}

	var matrixBytes []byte
	for _, v := range matrix {
		nrBuf := new(bytes.Buffer)
		err := binary.Write(nrBuf, binary.LittleEndian, v)
		if err != nil {
			log.Fatal(err)
		}
		matrixBytes = append(matrixBytes, nrBuf.Bytes()...)
	}
	err = p.Client.Set([]byte("rotmat"), matrixBytes)
	if err != nil {
		log.Fatalf("Error set: %s\n", err)
	}

	err = p.Client.GetRotationMatrix([]byte("rotmat"))
	if err != nil {
		log.Fatalf("Error GetRotationMatrix: %s\n", err)
	}

	p.DisableColumn(p.ColumnsNo - 1)

	start1 := time.Now()
	fpgaData, err := p.GetPerturbedRows(key, columnPermutation)
	if err != nil {
		log.Fatalf("Error GetPerturbedRows: %s\n", err)
	}
	t1 := float64(time.Since(start1).Nanoseconds()) / 1e3
	fmt.Printf("T1 = %f\n", t1)

	stringData := make([][]string, len(fpgaData[0])+1)
	for i := 0; i < len(fpgaData[0])+1; i++ {
		stringData[i] = make([]string, len(fpgaData))
	}
	for i := 0; i < len(fpgaData); i++ {
		stringData[0][i] = columns[i]
		for j := 1; j <= len(fpgaData[0]); j++ {
			stringData[j][i] = fmt.Sprintf("%f", fpgaData[i][j-1])
		}
	}
	pfout, err := os.Create(csvOut1FilePath)
	if err != nil {
		panic(err)
	}
	csvWriter := csv.NewWriter(pfout)
	err = csvWriter.WriteAll(stringData)
	if err != nil {
		panic(err)
	}
	csvWriter.Flush()

	// CPU
	for i := 0; i < p.ColumnsNo; i++ {
		p.DisableColumn(i)
	}

	start2 := time.Now()
	fileData, err := p.GetPerturbedRows(key, []int{})
	if err != nil {
		log.Fatalf("Error GetPerturbedRows: %s\n", err)
	}

	rotatedData := make([][]float64, len(fileData[0]))
	for i := range rotatedData {
		rotatedData[i] = make([]float64, len(fileData))
	}

	var rotated []float64
	for i := 0; i < len(columnPermutation); i += 3 {
		for j := 0; j < len(fileData[0]); j++ {
			rotated = rotpert.RotateVector3D(rotationMatrix, []float64{fileData[columnPermutation[i]][j], fileData[columnPermutation[i+1]][j],
				fileData[columnPermutation[i+2]][j]})
			for k := 0; k < 3; k++ {
				if i+k < len(data[0]) {
					rotatedData[j][columnPermutation[i+k]] = rotated[k]
				}
			}
		}
	}
	for i := 0; i < len(fileData[0]); i++ {
		rotatedData[i][len(data[0])] = fileData[len(data[0])][i]
	}
	t2 := float64(time.Since(start2).Nanoseconds()) / 1e3
	fmt.Printf("T2 = %f\n", t2)

	stringData = make([][]string, len(fileData[0])+1)
	for i := 0; i < len(fileData[0])+1; i++ {
		stringData[i] = make([]string, len(fileData))
	}
	for i := 0; i < len(fileData); i++ {
		stringData[0][i] = columns[i]
		for j := 1; j <= len(fileData[0]); j++ {
			stringData[j][i] = fmt.Sprintf("%f", rotatedData[j-1][i])
		}
	}
	pfout, err = os.Create(csvOut2FilePath)
	if err != nil {
		panic(err)
	}
	csvWriter = csv.NewWriter(pfout)
	err = csvWriter.WriteAll(stringData)
	if err != nil {
		panic(err)
	}
	csvWriter.Flush()
}
