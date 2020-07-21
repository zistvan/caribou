package parquet

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"

	"io"
	"math"
	"reflect"

	"multes_client_library_priv/ops"
	"multes_client_library_priv/rotpert"

	"github.com/apache/thrift/lib/go/thrift"
	"github.com/xitongsys/parquet-go/Compress"
	"github.com/xitongsys/parquet-go/Layout"
	"github.com/xitongsys/parquet-go/ParquetFile"
	"github.com/xitongsys/parquet-go/ParquetReader"
	"github.com/xitongsys/parquet-go/SchemaHandler"
	pq "github.com/xitongsys/parquet-go/parquet"
)

// A column chunk has multiple pages.
// We will serialize multiple pages of the same column chunk in the same value in order to reach minValueSize bytes.
const minValueSize = 8

// a generated file was created synthetically by transforming a .csv into parquet
const generatedFile = true

type Processor struct {
	client               *ops.Client
	parquetSchema        Schema
	columnsNo            int
	threadsNo            int
	enabledColumns       []bool
	outputColumns        []bool
	columnFilters        []func([]byte) bool
	valueNoOffsets       []int
	pageNoOffsets        []int
	pageOffsets          []int
	parquetFileMetaData  *pq.FileMetaData
	columnChunksValuesNo []int
	arrayDir             []byte
	ColumnPermutation    []int
	RotationMatrix       [][]float64
}

func NewProcessor(client *ops.Client, parquetSchema Schema, threadsNo ...int) (*Processor, error) {
	p := new(Processor)

	p.client = client

	p.parquetSchema = parquetSchema

	columnsNo := reflect.ValueOf(parquetSchema).NumField()
	p.columnsNo = columnsNo

	if len(threadsNo) > 0 {
		p.threadsNo = threadsNo[0]
	} else {
		p.threadsNo = 8
	}

	p.enabledColumns = make([]bool, columnsNo)
	for i := 0; i < columnsNo; i++ {
		p.enabledColumns[i] = true
	}

	p.outputColumns = make([]bool, columnsNo)

	p.columnFilters = make([]func([]byte) bool, columnsNo)
	for i := 0; i < columnsNo; i++ {
		p.columnFilters[i] = func([]byte) bool { return true }
	}

	p.valueNoOffsets = make([]int, columnsNo)

	p.pageNoOffsets = make([]int, columnsNo)

	p.pageOffsets = make([]int, columnsNo)

	p.parquetFileMetaData = nil

	p.columnChunksValuesNo = make([]int, columnsNo)

	return p, nil
}

func (processor *Processor) SetParquetSchema(parquetSchema Schema) error {
	newProcessor, err := NewProcessor(processor.client, parquetSchema, processor.threadsNo)
	*processor = *newProcessor
	if err != nil {
		return err
	}
	return nil
}

func (processor *Processor) SetThreadsNo(threadsNo int) error {
	if threadsNo <= 0 {
		return errors.New("Number of threads should be positive")
	}
	processor.threadsNo = threadsNo
	return nil
}

func (processor *Processor) resetOffsets() {
	for i := 0; i < processor.columnsNo; i++ {
		processor.valueNoOffsets[i] = 0
		processor.pageNoOffsets[i] = 0
		processor.pageOffsets[i] = 0
	}
}

func (processor *Processor) EnableColumn(colIdx int) {
	processor.enabledColumns[colIdx] = true
	processor.resetOffsets()
}

func (processor *Processor) DisableColumn(colIdx int) {
	processor.enabledColumns[colIdx] = false
	processor.resetOffsets()
}

func (processor *Processor) SetOutputColumn(colIdx int) {
	processor.outputColumns[colIdx] = true
	processor.resetOffsets()
}

func (processor *Processor) SetColumnFilter(colIdx int, filter func([]byte) bool) {
	processor.columnFilters[colIdx] = filter
	processor.resetOffsets()
}

func (processor *Processor) StoreFile(key []byte, parquetFilePath string) error {
	var err error

	divider, err := NewDivider(parquetFilePath, processor.parquetSchema, minValueSize, processor.threadsNo)
	if err != nil {
		return err
	}
	defer divider.Close()

	pageValues, err := divider.DivideFile()
	if err != nil {
		return err
	}

	// return c.ArraySet(key, pageValues)
	return processor.client.ArraySetN(key, pageValues, processor.threadsNo)
}

func (processor *Processor) GetFile(key []byte, parquetFilePath string) error {
	var err error

	pageValues, err := processor.client.ArrayGet(key)
	if err != nil {
		return err
	}
	if pageValues == nil {
		return errors.New("No value found at the given key")
	}

	// // test
	// err = os.Mkdir("out2", 0777)
	// if err != nil {
	// 	return err
	// }
	// for i, v := range pageValues {
	// 	fp, err := os.Create("out2/page" + strconv.Itoa(i))
	// 	if err != nil {
	// 		return err
	// 	}
	// 	defer fp.Close()
	// 	_, err = fp.Write(v)
	// 	if err != nil {
	// 		return err
	// 	}
	// 	fmt.Printf("Page %d len: %d\n", i, len(v))
	// }

	composer, err := NewComposer(pageValues, parquetFilePath, processor.parquetSchema)
	if err != nil {
		return err
	}
	defer composer.Close()

	err = composer.ComposeFile()
	if err != nil {
		return err
	}

	return nil
}

func (processor *Processor) GetMetaData(key []byte) (*pq.FileMetaData, []int, error) {
	var err error

	if len(processor.arrayDir) == 0 {
		processor.arrayDir, err = processor.client.GetArrayDir(key)
		if processor.arrayDir == nil {
			return nil, nil, nil
		}
		if err != nil {
			return nil, nil, err
		}
	}

	lastIdx := processor.arrayDir[len(processor.arrayDir)-ops.ArrIdxLen:]

	qKey := make([]byte, len(key)+ops.ArrIdxLen)

	copy(qKey, lastIdx)
	copy(qKey[ops.ArrIdxLen:], key)

	metaDataValue, err := processor.client.Get(qKey)
	if err != nil {
		return nil, nil, err
	}

	reader := bytes.NewReader(metaDataValue)
	tr := thrift.NewStreamTransportR(reader)
	parquetFileMetaData := pq.NewFileMetaData()
	err = parquetFileMetaData.Read(thrift.NewTCompactProtocolFactory().GetProtocol(tr))
	if err != nil {
		return nil, nil, err
	}
	processor.parquetFileMetaData = parquetFileMetaData

	pagesNo := make([]byte, 4)
	for i := 0; i < processor.columnsNo; i++ {
		_, err = tr.Read(pagesNo)
		if err != nil {
			return nil, nil, err
		}
		processor.columnChunksValuesNo[i] = int(pagesNo[0]) + (int(pagesNo[1]) << 8) + (int(pagesNo[2]) << 16) + (int(pagesNo[3]) << 24)
	}
	processor.columnChunksValuesNo = append([]int{0}, processor.columnChunksValuesNo...)

	return parquetFileMetaData, processor.columnChunksValuesNo, nil
}

func (processor *Processor) SetRotationMatrix(parquetFilePath string) error {
	fr, err := ParquetFile.NewLocalFileReader(parquetFilePath)
	if err != nil {
		return fmt.Errorf("Error NewLocalFileReader: %v", err)
	}
	pr, err := ParquetReader.NewParquetReader(fr, processor.parquetSchema.GetSchemaObjectReference(), int64(processor.threadsNo))
	if err != nil {
		return fmt.Errorf("Error NewParquetReader: %v", err)
	}

	perturbedColumnsIndices := make([]int, 0, processor.columnsNo)
	for i := 0; i < processor.columnsNo; i++ {
		if processor.enabledColumns[i] && !processor.outputColumns[i] {
			perturbedColumnsIndices = append(perturbedColumnsIndices, i)
		}
	}

	rowsNo := int(pr.GetNumRows())

	floatData := make([][]float64, rowsNo)
	for i := 0; i < rowsNo; i++ {
		floatData[i] = make([]float64, len(perturbedColumnsIndices))
	}

	slice := reflect.MakeSlice(reflect.SliceOf(reflect.TypeOf(processor.parquetSchema)), rowsNo, rowsNo)
	ptrSlice := reflect.New(slice.Type())
	ptrSlice.Elem().Set(slice)
	data := ptrSlice.Interface()

	err = pr.Read(data)
	if err != nil {
		return fmt.Errorf("Error Read: %v", err)
	}

	dataValue := reflect.ValueOf(data).Elem()

	for i := 0; i < dataValue.Len(); i++ {
		dataRow := dataValue.Index(i)
		for j := 0; j < len(perturbedColumnsIndices); j++ {
			floatData[i][j] = dataRow.Field(perturbedColumnsIndices[j]).Elem().Float()
		}
	}

	normalizedFloatData := rotpert.Normalize(floatData)

	processor.ColumnPermutation = rotpert.ColumnPermutation(len(perturbedColumnsIndices), false)

	processor.RotationMatrix = rotpert.GetBestRotationMatrix(normalizedFloatData, processor.ColumnPermutation)

	err = processor.client.SetRotationMatrix(processor.RotationMatrix)
	if err != nil {
		return fmt.Errorf("Error SetRotationMatrix: %v", err)
	}

	return processor.client.GetRotationMatrix()
}

func (processor *Processor) GetPerturbedRows(key []byte, n int) ([][]float64, error) {
	var err error

	if processor.parquetFileMetaData == nil {
		_, _, err = processor.GetMetaData(key)
		if err != nil {
			return nil, fmt.Errorf("Error GetMetaData: %s\n", err)
		}
	}

	if len(processor.arrayDir) == 0 {
		processor.arrayDir, err = processor.client.GetArrayDir(key)
		if processor.arrayDir == nil {
			return nil, nil
		}
		if err != nil {
			return nil, err
		}
	}

	perturbedColumnsIndices := make([]int, 0, processor.columnsNo)
	outputColumnsIndices := make([]int, 0, processor.columnsNo)
	for i := 0; i < processor.columnsNo; i++ {
		if processor.enabledColumns[i] {
			if processor.outputColumns[i] {
				outputColumnsIndices = append(outputColumnsIndices, i)
			} else {
				perturbedColumnsIndices = append(perturbedColumnsIndices, i)
			}
		}
	}

	// fmt.Printf("perturbedColumnsIndices = %v\n", perturbedColumnsIndices)
	// fmt.Printf("outputColumnsIndices = %v\n", outputColumnsIndices)
	// fmt.Printf("processor.ColumnPermutation = %v\n", processor.ColumnPermutation)

	keys := make([][]byte, 0, processor.columnChunksValuesNo[processor.columnsNo])
	getCondNo := 0
	getNo := 0

	if len(perturbedColumnsIndices) > 0 {
		for i := 0; i < len(processor.ColumnPermutation); i += 3 {
			for {
				done := false
				for j := 0; j < 3; j++ {
					if processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] >=
						processor.columnChunksValuesNo[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]+1]-
							processor.columnChunksValuesNo[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] {
						done = true
						break
					}
				}
				if done {
					break
				}

				for j := 0; j < 3; j++ {
					k, err := processor.client.ArrayGetElemKey(processor.arrayDir, key,
						processor.columnChunksValuesNo[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]]+
							processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]])
					if err != nil {
						return nil, err
					}
					keys = append(keys, k)
					getCondNo++
					processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]]++
				}
			}
			for j := 0; j < 3; j++ {
				processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] = 0
			}
		}
	}

	for i := 0; i < len(outputColumnsIndices); i++ {
		for processor.valueNoOffsets[outputColumnsIndices[i]] < processor.columnChunksValuesNo[outputColumnsIndices[i]+1]-
			processor.columnChunksValuesNo[outputColumnsIndices[i]] {

			k, err := processor.client.ArrayGetElemKey(processor.arrayDir, key, processor.columnChunksValuesNo[outputColumnsIndices[i]]+
				processor.valueNoOffsets[outputColumnsIndices[i]])
			if err != nil {
				return nil, err
			}
			keys = append(keys, k)
			getNo++
			processor.valueNoOffsets[outputColumnsIndices[i]]++

		}
		processor.valueNoOffsets[outputColumnsIndices[i]] = 0
	}

	pages, err := processor.client.GetBulkN(keys, getCondNo, getNo, n)
	if err != nil {
		return nil, err
	}

	outCols := make([][]float64, processor.columnsNo)
	pagesIdx := 0

	if len(perturbedColumnsIndices) > 0 {
		for i := 0; i < len(processor.ColumnPermutation); i += 3 {
			for {
				done := false
				for j := 0; j < 3; j++ {
					if processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] >=
						processor.columnChunksValuesNo[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]+1]-
							processor.columnChunksValuesNo[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] {
						done = true
						break
					}
				}
				if done {
					break
				}

				for j := 0; j < 3; j++ {
					if i+j < len(perturbedColumnsIndices) {
						for k := 0; k < len(pages[pagesIdx]); k += 8 {
							bits := binary.LittleEndian.Uint64(pages[pagesIdx][k : k+8])
							n := math.Float64frombits(bits)
							outCols[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] = append(outCols[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]], n)
						}
					}
					pagesIdx++
					processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]]++
				}
			}
			for j := 0; j < 3; j++ {
				processor.valueNoOffsets[perturbedColumnsIndices[processor.ColumnPermutation[i+j]]] = 0
			}
		}
	}

	for i := 0; i < len(outputColumnsIndices); i++ {
		for processor.valueNoOffsets[outputColumnsIndices[i]] < processor.columnChunksValuesNo[outputColumnsIndices[i]+1]-
			processor.columnChunksValuesNo[outputColumnsIndices[i]] {

			var k int
			if pages[pagesIdx][41] == 0x00 && pages[pagesIdx][42] == 0x03 {
				k = 49
			} else if pages[pagesIdx][41] == 0x02 && pages[pagesIdx][42] == 0x00 {
				k = 47
			}
			for ; k < len(pages[pagesIdx]); k += 8 {
				bits := binary.LittleEndian.Uint64(pages[pagesIdx][k : k+8])
				n := math.Float64frombits(bits)
				outCols[outputColumnsIndices[i]] = append(outCols[outputColumnsIndices[i]], n)
			}
			pagesIdx++
			processor.valueNoOffsets[outputColumnsIndices[i]]++

		}
		processor.valueNoOffsets[outputColumnsIndices[i]] = 0
	}

	return outCols, nil
}

func (processor *Processor) GetAllRows(key []byte) ([][]interface{}, []reflect.Kind, error) {
	var (
		outRows  [][]interface{}
		outTypes []reflect.Kind
		err      error
	)

	rows, types, cont, err := processor.GetRowBatch(key)
	outTypes = types
	//i := 1
	for err == nil && cont {
		//fmt.Printf("%d\n", i)
		//i++
		//fmt.Printf("\n*****\n%v %d*\n\n*%v %v\n\n***\n", rows, len(rows), types, cont)
		outRows = append(outRows, rows...)
		rows, _, cont, err = processor.GetRowBatch(key)
	}
	if err != nil {
		return nil, nil, fmt.Errorf("Error GetRowBatch: %s\n", err)
	}

	return outRows, outTypes, nil
}

func (processor *Processor) GetRowBatch(key []byte) ([][]interface{}, []reflect.Kind, bool, error) {
	var (
		outRows              [][]interface{}
		outUnfilteredColumns [][]interface{}
		outRowsNo            int
		outcolumnsNo         int
		filteredEntries      []bool
		filteredRowsNo       int
		outTypes             []reflect.Kind
		err                  error
	)

	schemaHandler, err := SchemaHandler.NewSchemaHandlerFromStruct(processor.parquetSchema.GetSchemaObjectReference())
	if err != nil {
		return nil, nil, false, fmt.Errorf("Error NewSchemaHandlerFromStruct: %s\n", err)
	}

	if processor.parquetFileMetaData == nil {
		_, _, err = processor.GetMetaData(key)
		if err != nil {
			return nil, nil, false, fmt.Errorf("Error GetMetaData: %s\n", err)
		}
	}

	firstEnabled := -1
	for i := 0; i < processor.columnsNo; i++ {
		if processor.enabledColumns[i] {
			firstEnabled = i
			break
		}
	}
	if firstEnabled == -1 {
		return nil, nil, false, errors.New("No columns enabled")
	}

	//fmt.Printf("\n***%d***%d***\n", processor.pageNoOffsets[firstEnabled], processor.columnChunksValuesNo[firstEnabled+1]-processor.columnChunksValuesNo[firstEnabled])
	// if there are more values to read from the first column
	if processor.valueNoOffsets[firstEnabled] < processor.columnChunksValuesNo[firstEnabled+1]-processor.columnChunksValuesNo[firstEnabled] {
		columnMetaData := processor.parquetFileMetaData.RowGroups[0].Columns[firstEnabled].MetaData
		switch columnMetaData.Type {
		case pq.Type_BYTE_ARRAY:
			outTypes = append(outTypes, reflect.String)
		case pq.Type_INT64:
			outTypes = append(outTypes, reflect.Int64)
		case pq.Type_DOUBLE:
			outTypes = append(outTypes, reflect.Float64)
		}

		pageValue, err := processor.client.ArrayGetElem(key, processor.columnChunksValuesNo[firstEnabled]+processor.valueNoOffsets[firstEnabled])
		if err != nil {
			return nil, nil, false, err
		}

		pageBuffer := bytes.NewBuffer(pageValue)
		thriftReader := thrift.NewStreamTransportR(pageBuffer)
		bufferedReader := thrift.NewTBufferedTransport(thriftReader, len(pageValue))

		outRowsNo = 0

		outUnfilteredColumns = append(outUnfilteredColumns, make([]interface{}, 0))

		for {
			page, err := Layout.ReadPageRawData(bufferedReader, schemaHandler, columnMetaData)
			if err != nil {
				break
			}

			if page.Header.GetType() == pq.PageType_DICTIONARY_PAGE {
				err = page.GetValueFromRawData(schemaHandler)
				if err != nil {
					return nil, nil, false, err
				}
			}

			uncompressed, err := Compress.Uncompress(page.RawData, page.CompressType)
			if err != nil {
				return nil, nil, false, err
			}

			var byteReader *bytes.Reader
			if generatedFile {
				if uncompressed[0] == 0x03 {
					byteReader = bytes.NewReader(uncompressed[7:])
				} else if uncompressed[0] == 0x02 {
					byteReader = bytes.NewReader(uncompressed[6:])
				}
			} else {
				byteReader = bytes.NewReader(uncompressed)
			}

			switch page.DataType {
			case pq.Type_BYTE_ARRAY:
				var entryLength int
				for {
					entryLengthBytes := make([]byte, 4)
					_, err = byteReader.Read(entryLengthBytes)
					if err != nil {
						break
					}
					entryLength = int(entryLengthBytes[0]) + (int(entryLengthBytes[1]) << 8) + (int(entryLengthBytes[2]) << 16) + (int(entryLengthBytes[3]) << 24)

					entry := make([]byte, entryLength)
					_, err = byteReader.Read(entry)
					if err != nil {
						break
					}
					outUnfilteredColumns[outcolumnsNo] = append(outUnfilteredColumns[outcolumnsNo], string(entry))
					if processor.columnFilters[firstEnabled](entry) {
						filteredEntries = append(filteredEntries, true)
						filteredRowsNo++
					} else {
						filteredEntries = append(filteredEntries, false)
					}
					outRowsNo++
				}
			case pq.Type_INT64:
				var entry int64
				for {
					entryBytes := make([]byte, 8)
					_, err = byteReader.Read(entryBytes)
					if err != nil {
						break
					}
					entry = int64(entryBytes[0]) + (int64(entryBytes[1]) << 8) + (int64(entryBytes[2]) << 16) + (int64(entryBytes[3]) << 24) +
						(int64(entryBytes[4]) << 32) + (int64(entryBytes[5]) << 40) + (int64(entryBytes[6]) << 48) + (int64(entryBytes[7]) << 56)
					outUnfilteredColumns[outcolumnsNo] = append(outUnfilteredColumns[outcolumnsNo], entry)
					if processor.columnFilters[firstEnabled](entryBytes) {
						filteredEntries = append(filteredEntries, true)
						filteredRowsNo++
					} else {
						filteredEntries = append(filteredEntries, false)
					}
					outRowsNo++
				}
			case pq.Type_DOUBLE:
				var entry float64
				for {
					entryBytes := make([]byte, 8)
					_, err = byteReader.Read(entryBytes)
					if err != nil {
						break
					}
					bits := binary.LittleEndian.Uint64(entryBytes)
					entry = math.Float64frombits(bits)
					outUnfilteredColumns[outcolumnsNo] = append(outUnfilteredColumns[outcolumnsNo], entry)
					if processor.columnFilters[firstEnabled](entryBytes) {
						filteredEntries = append(filteredEntries, true)
						filteredRowsNo++
					} else {
						filteredEntries = append(filteredEntries, false)
					}
					outRowsNo++
				}
			}
		}
		processor.valueNoOffsets[firstEnabled]++
		outcolumnsNo++

		// get outRowsNo rows from each of the remaining enabled columns
		for i := firstEnabled + 1; i < processor.columnsNo; i++ {
			if processor.enabledColumns[i] {

				columnMetaData := processor.parquetFileMetaData.RowGroups[0].Columns[i].MetaData
				switch columnMetaData.Type {
				case pq.Type_BYTE_ARRAY:
					outTypes = append(outTypes, reflect.String)
				case pq.Type_INT64:
					outTypes = append(outTypes, reflect.Int64)
				case pq.Type_DOUBLE:
					outTypes = append(outTypes, reflect.Float64)
				}

				// begin column processing
				outUnfilteredColumns = append(outUnfilteredColumns, make([]interface{}, outRowsNo))
				valuesRead := 0
				for valuesRead < outRowsNo {
					// fmt.Printf("\n\n*%d*%d*%d*%d*\n\n", processor.columnChunksValuesNo[i]+processor.valueNoOffsets[i],
					// 	processor.valueNoOffsets[i], processor.pageNoOffsets[i], processor.pageOffsets[i])
					pageValue, err := processor.client.ArrayGetElem(key, processor.columnChunksValuesNo[i]+processor.valueNoOffsets[i])
					if err != nil {
						return nil, nil, false, err
					}

					pageBuffer := bytes.NewBuffer(pageValue)
					thriftReader := thrift.NewStreamTransportR(pageBuffer)
					bufferedReader := thrift.NewTBufferedTransport(thriftReader, len(pageValue))

					pageNoOffset := 0
					for pageNoOffset < processor.pageNoOffsets[i] {
						_, err = Layout.ReadPageRawData(bufferedReader, schemaHandler, columnMetaData)
						if err != nil {
							break
						}
						pageNoOffset++
					}

					//fmt.Printf("\n1pageNoOffset = %d\n", pageNoOffset)

					page, err := Layout.ReadPageRawData(bufferedReader, schemaHandler, columnMetaData)
					if err != nil {
						processor.valueNoOffsets[i]++
						processor.pageNoOffsets[i] = 0
						processor.pageOffsets[i] = 0
						//fmt.Printf("\n*******************************\n")
						continue
					}

					if page.Header.GetType() == pq.PageType_DICTIONARY_PAGE {
						pageData := page.RawData
						err = page.GetValueFromRawData(schemaHandler)
						if err != nil {
							return nil, nil, false, err
						}
						page.RawData = pageData
					}

					uncompressed, err := Compress.Uncompress(page.RawData, page.CompressType)
					if err != nil {
						return nil, nil, false, err
					}

					byteReader := bytes.NewReader(uncompressed)
					if generatedFile && processor.pageOffsets[i] == 0 {
						if uncompressed[0] == 0x03 {
							byteReader = bytes.NewReader(uncompressed[7:])
						} else if uncompressed[0] == 0x02 {
							byteReader = bytes.NewReader(uncompressed[6:])
						}
					}

					_, err = byteReader.Seek(int64(processor.pageOffsets[i]), io.SeekStart)
					if err != nil {
						return nil, nil, false, err
					}

					for {
						switch page.DataType {
						case pq.Type_BYTE_ARRAY:
							var entryLength int
							for {
								entryLengthBytes := make([]byte, 4)
								_, err = byteReader.Read(entryLengthBytes)
								if err != nil {
									break
								}
								entryLength = int(entryLengthBytes[0]) + (int(entryLengthBytes[1]) << 8) + (int(entryLengthBytes[2]) << 16) + (int(entryLengthBytes[3]) << 24)

								entry := make([]byte, entryLength)
								_, err = byteReader.Read(entry)
								if err != nil {
									break
								}
								outUnfilteredColumns[outcolumnsNo][valuesRead] = string(entry)
								if !processor.columnFilters[i](entry) {
									if filteredEntries[valuesRead] {
										filteredEntries[valuesRead] = false
										filteredRowsNo--
									}
								}
								valuesRead++
								if valuesRead == outRowsNo {
									//fmt.Printf("\n**%d**\n", byteReader.Len())
									if byteReader.Len() != 0 {
										processor.pageOffsets[i] = len(uncompressed) - byteReader.Len()
										processor.pageNoOffsets[i] = pageNoOffset
									} else {
										processor.pageNoOffsets[i] = pageNoOffset + 1
									}
									break
								}
							}
						case pq.Type_INT64:
							var entry int64
							for {
								entryBytes := make([]byte, 8)
								_, err = byteReader.Read(entryBytes)
								if err != nil {
									break
								}
								entry = int64(entryBytes[0]) + (int64(entryBytes[1]) << 8) + (int64(entryBytes[2]) << 16) + (int64(entryBytes[3]) << 24) +
									(int64(entryBytes[4]) << 32) + (int64(entryBytes[5]) << 40) + (int64(entryBytes[6]) << 48) + (int64(entryBytes[7]) << 56)
								outUnfilteredColumns[outcolumnsNo][valuesRead] = entry
								if !processor.columnFilters[i](entryBytes) {
									if filteredEntries[valuesRead] {
										filteredEntries[valuesRead] = false
										filteredRowsNo--
									}
								}
								valuesRead++
								if valuesRead == outRowsNo {
									//fmt.Printf("\n**%d**\n", byteReader.Len())
									if byteReader.Len() != 0 {
										processor.pageOffsets[i] = len(uncompressed) - byteReader.Len()
										processor.pageNoOffsets[i] = pageNoOffset
									} else {
										processor.pageNoOffsets[i] = pageNoOffset + 1
									}
									break
								}
							}
						case pq.Type_DOUBLE:
							var entry float64
							for {
								entryBytes := make([]byte, 8)
								_, err = byteReader.Read(entryBytes)
								if err != nil {
									break
								}
								bits := binary.LittleEndian.Uint64(entryBytes)
								entry = math.Float64frombits(bits)
								outUnfilteredColumns[outcolumnsNo][valuesRead] = entry
								if !processor.columnFilters[i](entryBytes) {
									if filteredEntries[valuesRead] {
										filteredEntries[valuesRead] = false
										filteredRowsNo--
									}
								}
								valuesRead++
								if valuesRead == outRowsNo {
									//fmt.Printf("\n**%d**\n", byteReader.Len())
									if byteReader.Len() != 0 {
										processor.pageOffsets[i] = len(uncompressed) - byteReader.Len()
										processor.pageNoOffsets[i] = pageNoOffset
									} else {
										processor.pageNoOffsets[i] = pageNoOffset + 1
									}
									break
								}
							}
						}
						if valuesRead == outRowsNo {
							break
						}

						page, err = Layout.ReadPageRawData(bufferedReader, schemaHandler, columnMetaData)
						if err != nil {
							break
						}
						pageNoOffset++

						//fmt.Printf("\n2pageNoOffset = %d\n", pageNoOffset)

						if page.Header.GetType() == pq.PageType_DICTIONARY_PAGE {
							pageData := page.RawData
							err = page.GetValueFromRawData(schemaHandler)
							if err != nil {
								return nil, nil, false, err
							}
							page.RawData = pageData
						}

						uncompressed, err = Compress.Uncompress(page.RawData, page.CompressType)
						if err != nil {
							return nil, nil, false, err
						}

						byteReader = bytes.NewReader(uncompressed)
						if generatedFile {
							if uncompressed[0] == 0x03 {
								byteReader = bytes.NewReader(uncompressed[7:])
							} else if uncompressed[0] == 0x02 {
								byteReader = bytes.NewReader(uncompressed[6:])
							}
						}
					}
					if valuesRead != outRowsNo {
						processor.valueNoOffsets[i]++
						processor.pageNoOffsets[i] = 0
						processor.pageOffsets[i] = 0
						//fmt.Printf("\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n")
					} else {
						outcolumnsNo++
					}
				}
				// end column processing

			}
		}
	} else {
		return nil, nil, false, nil
	}

	//fmt.Printf("XXX%dXXX", filteredRowsNo)
	outRows = make([][]interface{}, filteredRowsNo)
	for i := 0; i < filteredRowsNo; i++ {
		outRows[i] = make([]interface{}, outcolumnsNo)
	}

	currentOutRow := 0
	for i := 0; i < outRowsNo; i++ {
		if filteredEntries[i] {
			for j := 0; j < outcolumnsNo; j++ {
				outRows[currentOutRow][j] = outUnfilteredColumns[j][i]
			}
			currentOutRow++
		}
	}

	return outRows, outTypes, true, nil
}
