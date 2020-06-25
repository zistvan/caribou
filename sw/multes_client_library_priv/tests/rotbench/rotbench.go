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

	"github.com/xitongsys/parquet-go/ParquetFile"
	"github.com/xitongsys/parquet-go/ParquetReader"
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
	fr, err := ParquetFile.NewLocalFileReader(inFilePath)
	if err != nil {
		log.Fatalf("Error file: %v\n", err)
	}
	pr, err := ParquetReader.NewParquetReader(fr, schema.GetSchemaObjectReference(), 8)
	if err != nil {
		log.Fatalf("Error reader: %v\n", err)
	}

	start2 := time.Now()
	n := int(pr.GetNumRows())

	f := make([]parquet.PimaIndiansDiabetesData, n)

	err = pr.Read(&f)
	if err != nil {
		log.Fatalf("Error read: %v\n", err)
	}

	rotatedData := make([][]float64, n)
	for i := range rotatedData {
		rotatedData[i] = make([]float64, 9)
	}

	var rotated []float64
	for i := 0; i < n; i++ {
		rotated = rotpert.RotateVector3D(rotationMatrix, []float64{*f[i].Pregnancies, *f[i].Glucose, *f[i].BloodPressure})
		for k := 0; k < 3; k++ {
			rotatedData[i][0+k] = rotated[k]
		}
		rotated = rotpert.RotateVector3D(rotationMatrix, []float64{*f[i].SkinThickness, *f[i].Insulin, *f[i].BMI})
		for k := 0; k < 3; k++ {
			rotatedData[i][3+k] = rotated[k]
		}
		rotated = rotpert.RotateVector3D(rotationMatrix, []float64{*f[i].DiabetesPedigreeFunction, *f[i].Age, *f[i].BMI})
		for k := 0; k < 2; k++ {
			rotatedData[i][6+k] = rotated[k]
		}
		rotatedData[i][8] = *f[i].Outcome
	}

	t2 := float64(time.Since(start2).Nanoseconds()) / 1e3
	fmt.Printf("T2 = %f\n", t2)

	stringData = make([][]string, n+1)
	for i := 0; i < n+1; i++ {
		stringData[i] = make([]string, 9)
	}
	for i := 0; i < 9; i++ {
		stringData[0][i] = columns[i]
		for j := 1; j <= n; j++ {
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
