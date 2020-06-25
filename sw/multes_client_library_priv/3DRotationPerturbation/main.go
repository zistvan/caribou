package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
)

// const inFilePath = "bank_labeled.csv"
// const outFilePath = "bank_transformed.csv"

// /*
// age*	job	marital	education	default	balance*	housing	loan	contact	day*	month	duration*	campaign*	pdays*
// previous*	poutcome
// */

// var transformColumns = []string{"age",
// 	//"job",
// 	//"marital",
// 	//"education",
// 	//"default",
// 	"balance",
// 	//"housing",
// 	//"loan",
// 	//"contact",
// 	"day",
// 	//"month",
// 	//"duration",
// 	"campaign",
// 	"pdays",
// 	"previous",
// 	/*"poutcome"*/}

// var outputColumns = []string{"y"}

// const inFilePath = "banknote.csv"
// const outFilePath = "banknote_transformed.csv"

// var transformColumns = []string{"variance",
// 	"skewness",
// 	"curtosis",
// 	"entropy"}

// var outputColumns = []string{"class"}

const inFilePath = "diabetes.csv"
const outFilePath = "diabetes_transformed.csv"

var transformColumns = []string{"Pregnancies",
	"Glucose",
	"BloodPressure",
	"SkinThickness",
	"Insulin",
	"BMI",
	"DiabetesPedigreeFunction",
	"Age"}

var outputColumns = []string{"Outcome"}

func computePrivacyVariances(originalData [][]float64, transformedData [][]float64) []float64 {
	privacyVariances := make([]float64, len(originalData[0]))

	for i := range originalData {
		for j := range originalData[0] {
			privacyVariances[j] += math.Abs(math.Abs(originalData[i][j]) - math.Abs(transformedData[i][j]))
		}
	}

	for j := range originalData[0] {
		privacyVariances[j] /= float64(len(originalData))
	}

	return privacyVariances
}

func computeVoD(originalData [][]float64, transformedData [][]float64) {
	diffData := make([][]float64, len(originalData))
	for i := range diffData {
		diffData[i] = make([]float64, len(originalData[0]))
	}
	for i := range originalData {
		for j := range originalData[0] {
			diffData[i][j] += math.Abs(math.Abs(originalData[i][j]) - math.Abs(transformedData[i][j]))
		}
	}

	meanDiffData := make([]float64, len(originalData[0]))
	for i := range originalData {
		for j := range originalData[0] {
			meanDiffData[j] += diffData[i][j]
		}
	}
	for j := range originalData[0] {
		meanDiffData[j] /= float64(len(originalData))
	}

	varDiffData := make([]float64, len(originalData[0]))
	for i := range originalData {
		for j := range originalData[0] {
			varDiffData[j] += diffData[i][j] - meanDiffData[j]
		}
	}
	for j := range originalData[0] {
		varDiffData[j] /= float64(len(originalData))
	}

	fmt.Println("GGG:")
	fmt.Println(varDiffData)
}

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

	// writer := csv.NewWriter(pf)
	// defer writer.Flush()

	// err = writer.WriteAll(stringData)
	// if err != nil {
	// 	panic(err)
	// }

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

	transformedData := rotationTransformation(data)

	privacyVariances := computePrivacyVariances(data, transformedData)
	computeVoD(data, transformedData)

	fmt.Println(privacyVariances)

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

	for i, dataRecord := range transformedData {
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
