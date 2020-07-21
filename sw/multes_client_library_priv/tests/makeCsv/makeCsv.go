package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	var (
		err        error
		inFilePath string
		rowsNo     int
	)

	flag.StringVar(&inFilePath, "f", "bank_labeled.csv", "Path to the .csv input file.")
	flag.IntVar(&rowsNo, "r", 2000, "No of rows in the output file")
	flag.Parse()

	inFilePathWithoutExtension := inFilePath[:strings.IndexByte(inFilePath, '.')]

	pfin, err := os.Open(inFilePath)
	if err != nil {
		panic(err)
	}

	csvReader := csv.NewReader(pfin)

	csvDataString, err := csvReader.ReadAll()
	if err != nil {
		panic(err)
	}
	pfin.Close()

	pfout, err := os.Create(inFilePathWithoutExtension + strconv.Itoa(rowsNo) + ".csv")
	if err != nil {
		panic(err)
	}

	csvWriter := csv.NewWriter(pfout)

	err = csvWriter.Write(csvDataString[0])
	if err != nil {
		panic(err)
	}

	l := len(csvDataString) - 1
	for i := 0; i < rowsNo; i++ {
		err = csvWriter.Write(csvDataString[1+i%l])
		if err != nil {
			panic(err)
		}
		if i >= 1000 && i%1000 == 0 {
			fmt.Printf("%d ", i)
		}
	}
	csvWriter.Flush()
}
