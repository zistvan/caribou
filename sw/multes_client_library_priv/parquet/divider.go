package parquet

import (
	"bytes"
	"context"
	"encoding/binary"
	"fmt"

	"github.com/apache/thrift/lib/go/thrift"

	"github.com/xitongsys/parquet-go/Layout"
	"github.com/xitongsys/parquet-go/ParquetFile"
	"github.com/xitongsys/parquet-go/ParquetReader"
	"github.com/xitongsys/parquet-go/parquet"
)

// var ok = true
// var col = 0

type Divider struct {
	reader       *ParquetReader.ParquetReader
	serializer   *thrift.TSerializer
	pagesRead    int
	minValueSize int
	pageValues   [][]byte
}

func NewDivider(parquetFilePath string, parquetSchema Schema, minValueSize int, threadsNo int) (*Divider, error) {
	d := new(Divider)
	var err error

	fr, err := ParquetFile.NewLocalFileReader(parquetFilePath)
	if err != nil {
		return nil, err
	}
	pr, err := ParquetReader.NewParquetReader(fr, parquetSchema.GetSchemaObjectReference(), int64(threadsNo))
	if err != nil {
		return nil, err
	}
	d.reader = pr

	ts := thrift.NewTSerializer()
	ts.Protocol = thrift.NewTCompactProtocolFactory().GetProtocol(ts.Transport)
	d.serializer = ts

	d.minValueSize = minValueSize

	// // test
	// err = os.Mkdir("out", 0777)
	// if err != nil {
	// 	return nil, err
	// }
	// err = os.Mkdir("out1", 0777)
	// if err != nil {
	// 	return nil, err
	// }

	return d, nil
}

func (divider *Divider) Close() {
	divider.reader.ReadStop()
	divider.reader.PFile.Close()
}

func readPageStruct(column *ParquetReader.ColumnBufferType) (*Layout.Page, error) {
	var err error
	if column.ChunkReadValues < column.ChunkHeader.MetaData.NumValues {
		page, err := Layout.ReadPageRawData(column.ThriftReader, column.SchemaHandler, column.ChunkHeader.MetaData)
		if err != nil {
			return nil, err
		}
		pageData := page.RawData // !!! important !!! (I guess the other functions modify the page struct)
		numValues, numRows, err := page.GetRLDLFromRawData(column.SchemaHandler)
		if err != nil {
			return nil, err
		}
		page.RawData = pageData // !!! important !!!
		if page.Header.GetType() == parquet.PageType_DICTIONARY_PAGE {
			err = page.GetValueFromRawData(column.SchemaHandler)
			if err != nil {
				return nil, err
			}
			column.DictPage = page
			page.RawData = pageData
			return page, nil
		}
		if column.DataTable == nil {
			column.DataTable = Layout.NewTableFromTable(page.DataTable)
		}
		column.DataTable.Merge(page.DataTable)
		column.ChunkReadValues += numValues
		column.DataTableNumRows += numRows
		return page, nil
	}
	err = column.NextRowGroup()
	if err != nil {
		return nil, err
	}
	return readPageStruct(column)
}

func (divider *Divider) readPagesFromColumn(column *ParquetReader.ColumnBufferType) error {
	var err error

	//col++

	// // test
	// fp, err := os.Create("out/page" + strconv.Itoa(divider.pagesRead))
	// if err != nil {
	// 	return err
	// }
	// defer fp.Close()

	// // test
	// fp1, err := os.Create("out1/pageValues" + strconv.Itoa(divider.pagesRead))
	// if err != nil {
	// 	return err
	// }
	// defer fp1.Close()

	divider.pageValues = append(divider.pageValues, make([]byte, 0, divider.minValueSize))

	page, err := readPageStruct(column)
	for err == nil {
		if page != nil {
			if len(divider.pageValues[divider.pagesRead]) >= divider.minValueSize {
				divider.pagesRead++
				divider.pageValues = append(divider.pageValues, make([]byte, 0, divider.minValueSize))

				// // test
				// _, err = fp.Write([]byte("XXXXXXXXXXXX"))
				// if err != nil {
				// 	return err
				// }

				// // test
				// _, err = fp1.Write([]byte("XXXXXXXXXXXX"))
				// if err != nil {
				// 	return err
				// }
			}

			// headerBuff, err := divider.serializer.Write(context.TODO(), page.Header)
			// if err != nil {
			// 	return err
			// }

			// divider.pageValues[divider.pagesRead] = append(divider.pageValues[divider.pagesRead], headerBuff...)
			divider.pageValues[divider.pagesRead] = append(divider.pageValues[divider.pagesRead], page.RawData...)

			// // test
			// uncompressed, err := Compress.Uncompress(page.RawData, page.CompressType)
			// if err != nil {
			// 	return err
			// }
			// // if ok && col == 2 {
			// // 	f, err := os.Create("out1.txt")
			// // 	if err != nil {
			// // 		return err
			// // 	}
			// // 	f.Write(page.RawData)
			// // 	ok = false
			// // }
			// _, err = fp1.Write([]byte("*********"))
			// if err != nil {
			// 	return err
			// }
			// _, err = fp1.Write(uncompressed)
			// if err != nil {
			// 	return err
			// }

			// // test
			// _, err = fp.Write([]byte("*********"))
			// if err != nil {
			// 	return err
			// }
			// // _, err = fp.Write(headerBuff)
			// // if err != nil {
			// // 	return err
			// // }
			// // _, err = fp.Write([]byte("+++++++++"))
			// // if err != nil {
			// // 	return err
			// // }
			// _, err = fp.Write(page.RawData)
			// if err != nil {
			// 	return err
			// }
		}
		page, err = readPageStruct(column)
	}
	divider.pagesRead++

	return nil
}

func (divider *Divider) readMetaData(columnChunksValuesNo []int) error {
	// // test
	// fp, err := os.Create("out/meta")
	// if err != nil {
	// 	return err
	// }
	// defer fp.Close()

	fmt.Printf("%v\n", columnChunksValuesNo)

	footerBuff, err := divider.serializer.Write(context.TODO(), divider.reader.Footer)
	if err != nil {
		return err
	}

	var metadataBuff bytes.Buffer
	_, err = metadataBuff.Write(footerBuff)
	if err != nil {
		return err
	}

	// // test
	// _, err = fp.Write(footerBuff)
	// if err != nil {
	// 	return err
	// }

	for _, v := range columnChunksValuesNo {
		err = binary.Write(&metadataBuff, binary.LittleEndian, int32(v))
		if err != nil {
			return err
		}

		// // test
		// err = binary.Write(fp, binary.LittleEndian, int32(v))
		// if err != nil {
		// 	return err
		// }
	}

	divider.pageValues = append(divider.pageValues, metadataBuff.Bytes())

	return nil
}

func (divider *Divider) DivideFile() ([][]byte, error) {
	var err error

	columns := divider.reader.ColumnBuffers
	columnsNo := len(columns)

	// in this array we will hold how many pages went into each column chunk
	// it will be serialized at the end of the last page
	columnChunksValuesNo := make([]int, columnsNo)

	for i := 0; i < columnsNo; i++ {
		err = divider.readPagesFromColumn(columns[divider.reader.SchemaHandler.IndexMap[int32(i+1)]])
		if err != nil {
			divider.Close()
			return nil, err
		}
		columnChunksValuesNo[i] = divider.pagesRead
	}

	err = divider.readMetaData(columnChunksValuesNo)
	if err != nil {
		divider.Close()
		return nil, err
	}

	return divider.pageValues, nil
}
