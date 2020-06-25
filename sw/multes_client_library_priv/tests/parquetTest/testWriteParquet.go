package main

import (
	"fmt"

	"github.com/xitongsys/parquet-go/ParquetFile"
	"github.com/xitongsys/parquet-go/ParquetWriter"
)

type column struct {
	name           string
	valType        string
	repetitionType string
}

func testWriteParquet() {
	columns := []column{{"Id", "INT64", "REQUIRED"}, {"Name", "UTF8", "REQUIRED"}}
	rows := [][]interface{}{{1, "name1"}, {2, "name2"}, {3, "name3"}}

	fp, err := ParquetFile.NewLocalFileWriter("write.parquet")
	if err != nil {
		panic(err)
	}

	md := make([]string, len(columns))
	for i, column := range columns {
		md[i] = fmt.Sprintf("name=%s, type=%s, repetitiontype=%s", column.name, column.valType, column.repetitionType)
	}

	writer, err := ParquetWriter.NewCSVWriter(md, fp, 8)
	if err != nil {
		panic(err)
	}

	for _, row := range rows {
		rec := make([]*string, len(row))
		for j := 0; j < len(row); j++ {
			value := fmt.Sprintf("%v", row[j])
			rec[j] = &value
		}
		err = writer.WriteString(rec)
		if err != nil {
			panic(err)
		}
	}

	err = writer.WriteStop()
	if err != nil {
		panic(err)
	}
}
