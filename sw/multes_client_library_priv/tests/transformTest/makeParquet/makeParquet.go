package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"multes_client_library_priv/parquet"

	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/xitongsys/parquet-go-source/local"
	"github.com/xitongsys/parquet-go/ParquetWriter"
	pq "github.com/xitongsys/parquet-go/parquet"
)

func main() {
	var (
		err        error
		inFilePath string
	)

	flag.StringVar(&inFilePath, "f", "bank_labeled.csv", "Path to the .csv input file.")
	flag.Parse()

	inFilePathWithoutExtension := inFilePath[:strings.IndexByte(inFilePath, '.')]
	parquetFilePath := fmt.Sprintf("%s.parquet", inFilePathWithoutExtension)

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

	fw, err := local.NewLocalFileWriter(parquetFilePath)
	if err != nil {
		panic(err)
	}
	defer fw.Close()

	if strings.Contains(inFilePath, "bank") {
		var schemaStruct parquet.BankClientMarketingData

		pw, err := ParquetWriter.NewParquetWriter(fw, &schemaStruct, 4)
		if err != nil {
			panic(err)
		}

		pw.RowGroupSize = 1024 * 1024 * 1024 * 1024
		pw.CompressionType = pq.CompressionCodec_UNCOMPRESSED
		pw.PageSize = 2000

		for _, csvRowString := range csvDataString[1:] {
			for i, csvElemString := range csvRowString {
				csvElemFloat, err := strconv.ParseFloat(csvElemString, 64)
				if err != nil {
					panic(err)
				}
				reflect.ValueOf(&schemaStruct).Elem().Field(i).Set(reflect.ValueOf(&csvElemFloat))
			}

			err = pw.Write(schemaStruct)
			if err != nil {
				panic(err)
			}
		}

		err = pw.WriteStop()
		if err != nil {
			panic(err)
		}
	} else if strings.Contains(inFilePath, "diabetes") {
		var schemaStruct parquet.PimaIndiansDiabetesData

		pw, err := ParquetWriter.NewParquetWriter(fw, &schemaStruct, 4)
		if err != nil {
			panic(err)
		}

		pw.RowGroupSize = 1024 * 1024 * 1024 * 1024
		pw.CompressionType = pq.CompressionCodec_UNCOMPRESSED
		pw.PageSize = 2000

		for _, csvRowString := range csvDataString[1:] {
			for i, csvElemString := range csvRowString {
				csvElemFloat, err := strconv.ParseFloat(csvElemString, 64)
				if err != nil {
					panic(err)
				}
				reflect.ValueOf(&schemaStruct).Elem().Field(i).Set(reflect.ValueOf(&csvElemFloat))
			}

			err = pw.Write(schemaStruct)
			if err != nil {
				panic(err)
			}
		}

		err = pw.WriteStop()
		if err != nil {
			panic(err)
		}
	}
}
