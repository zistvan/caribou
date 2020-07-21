package main

import (
	"encoding/csv"
	"fmt"
	"multes_client_library_priv/rotpert"
	"os"
	"strconv"
	"time"
)

const inFilePath = "bank_labeled50000.csv"
const outFilePath = "bank_transformed.csv"

var transformColumns = []string{"age",
	"job",
	"marital",
	"education",
	"default",
	"balance",
	"housing",
	"loan",
	"contact",
	"day",
	"month",
	"duration",
	"campaign",
	"pdays",
	"previous",
	"poutcome"}

var outputColumns = []string{"y"}

// const inFilePath = "banknote.csv"
// const outFilePath = "banknote_transformed.csv"

// var transformColumns = []string{"variance",
// 	"skewness",
// 	"curtosis",
// 	"entropy"}

// var outputColumns = []string{"class"}

// const inFilePath = "diabetes.csv"
// const outFilePath = "diabetes_transformed.csv"

// var transformColumns = []string{"Pregnancies",
// 	"Glucose",
// 	"BloodPressure",
// 	"SkinThickness",
// 	"Insulin",
// 	"BMI",
// 	"DiabetesPedigreeFunction",
// 	"Age"}

// var outputColumns = []string{"Outcome"}

func main() {
	pf, err := os.Open(inFilePath)
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

	columnPermutation := rotpert.ColumnPermutation(len(data[0]), false)

	rotationMatrix := rotpert.GetBestRotationMatrix(normalizedData, columnPermutation)

	start1 := time.Now()

	var d [][]float64
	for i := 0; i < 10; i++ {
		d = rotpert.RotateData3D(data, rotationMatrix, columnPermutation)
	}

	t1 := float64(time.Since(start1).Microseconds()) / 1e6
	fmt.Printf("T1 = %f\n", t1/10)

	pf, err = os.Create(outFilePath)
	if err != nil {
		panic(err)
	}
	defer pf.Close()

	writer := csv.NewWriter(pf)
	defer writer.Flush()

	stringData := make([][]string, len(data)+1)
	for i := range stringData {
		stringData[i] = make([]string, len(data[0])+len(outputColumns))
	}

	copy(stringData[0][0:len(data[0])], transformColumns)
	copy(stringData[0][len(data[0]):len(data[0])+len(outputColumns)], outputColumns)

	for i, dataRecord := range d {
		for j, v := range dataRecord {
			stringData[i+1][j] = fmt.Sprintf("%f", v)
		}
		for j := range outputColumns {
			stringData[i+1][len(data[0])+j] = records[i+1][outputColumnsMap[j]]
		}
	}

	err = writer.WriteAll(stringData)
	if err != nil {
		panic(err)
	}
}
