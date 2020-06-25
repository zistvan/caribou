package parquet

import (
	"bytes"
	"context"
	"encoding/binary"
	"os"

	"github.com/apache/thrift/lib/go/thrift"
	"github.com/xitongsys/parquet-go/Layout"
	"github.com/xitongsys/parquet-go/SchemaHandler"
	"github.com/xitongsys/parquet-go/parquet"
)

type Composer struct {
	filePtr       *os.File
	serializer    *thrift.TSerializer
	pageValues    [][]byte
	schemaHandler *SchemaHandler.SchemaHandler
	bytesWritten  int
}

func NewComposer(pageValues [][]byte, parquetFilePath string, parquetSchema ParquetSchema) (*Composer, error) {
	c := new(Composer)
	var err error

	fp, err := os.Create(parquetFilePath)
	if err != nil {
		return nil, err
	}

	c.filePtr = fp

	ts := thrift.NewTSerializer()
	ts.Protocol = thrift.NewTCompactProtocolFactory().GetProtocol(ts.Transport)
	c.serializer = ts

	c.pageValues = pageValues

	schemaHandler, err := SchemaHandler.NewSchemaHandlerFromStruct(parquetSchema.GetSchemaObjectReference())
	if err != nil {
		return nil, err
	}
	c.schemaHandler = schemaHandler

	return c, nil
}

func (composer *Composer) Close() {
	composer.filePtr.Close()
}

func (composer *Composer) writeMagicNumber() error {
	n, err := composer.filePtr.Write([]byte("PAR1"))
	if err != nil {
		return err
	}

	composer.bytesWritten += n

	return nil
}

func (composer *Composer) writeMetaData(parquetFileMetaData *parquet.FileMetaData) error {
	var (
		err error
		n   int
	)

	metaDataBuff, err := composer.serializer.Write(context.TODO(), parquetFileMetaData)
	if err != nil {
		return err
	}

	//fmt.Printf("%s", hex.Dump(metaDataBuff))

	n, err = composer.filePtr.Write(metaDataBuff)
	if err != nil {
		return err
	}
	composer.bytesWritten += n

	metaDataSizeBuff := make([]byte, 4)
	binary.LittleEndian.PutUint32(metaDataSizeBuff, uint32(len(metaDataBuff)))

	n, err = composer.filePtr.Write(metaDataSizeBuff)
	if err != nil {
		return err
	}
	composer.bytesWritten += n

	return nil
}

func (composer *Composer) writePage(page *Layout.Page) error {
	var (
		err error
		n   int
	)

	headerBuff, err := composer.serializer.Write(context.TODO(), page.Header)
	if err != nil {
		return err
	}

	n, err = composer.filePtr.Write(headerBuff)
	if err != nil {
		return err
	}
	composer.bytesWritten += n

	n, err = composer.filePtr.Write(page.RawData)
	if err != nil {
		return err
	}
	composer.bytesWritten += n

	return nil
}

func (composer *Composer) writeChunk(firstPageIdx int, lastPageIdx int, columnMetaData *parquet.ColumnMetaData) (*Layout.Chunk, error) {
	fileOffset := int64(composer.bytesWritten)

	pages := make([]*Layout.Page, 0)

	for i := 0; i < lastPageIdx-firstPageIdx; i++ {
		pageBytes := composer.pageValues[firstPageIdx+i]
		pageBuffer := bytes.NewBuffer(pageBytes)

		thriftReader := thrift.NewStreamTransportR(pageBuffer)
		bufferedReader := thrift.NewTBufferedTransport(thriftReader, len(pageBytes))

		for {
			page, err := Layout.ReadPageRawData(bufferedReader, composer.schemaHandler, columnMetaData)
			if err != nil {
				break
			}

			if page.Header.GetType() == parquet.PageType_DICTIONARY_PAGE {
				err = page.GetValueFromRawData(composer.schemaHandler)
				if err != nil {
					return nil, err
				}
			}

			pages = append(pages, page)

			err = composer.writePage(page)
			if err != nil {
				return nil, err
			}
		}
	}

	chunk := Layout.PagesToChunk(pages)
	chunk.ChunkHeader.FileOffset = fileOffset
	chunk.ChunkHeader.MetaData.DataPageOffset = fileOffset

	meta := chunk.ChunkHeader.MetaData
	path := make([]string, 1)
	path[0] = meta.PathInSchema[1]
	meta.PathInSchema = path

	return chunk, nil
}

func (composer *Composer) writeRowGroup(parquetFileMetaData *parquet.FileMetaData, columnChunksValuesNo []int) (*parquet.RowGroup, error) {
	rowGroup := parquet.NewRowGroup()
	var err error

	columnsNo := len(columnChunksValuesNo)
	columnChunks := make([]*Layout.Chunk, columnsNo)
	columnChunksValuesNo = append([]int{0}, columnChunksValuesNo...)
	for i := 0; i < columnsNo; i++ {
		columnChunks[i], err = composer.writeChunk(columnChunksValuesNo[i], columnChunksValuesNo[i+1],
			parquetFileMetaData.RowGroups[0].Columns[i].MetaData)
		if err != nil {
			return nil, err
		}

		rowGroup.TotalByteSize += columnChunks[i].ChunkHeader.MetaData.TotalCompressedSize

		rowGroup.Columns = append(rowGroup.Columns, columnChunks[i].ChunkHeader)
	}

	rowGroup.NumRows += columnChunks[0].ChunkHeader.MetaData.NumValues

	return rowGroup, nil
}

func (composer *Composer) getMetaData() (*parquet.FileMetaData, []int, error) {
	parquetFileMetaData := parquet.NewFileMetaData()

	reader := bytes.NewReader(composer.pageValues[len(composer.pageValues)-1])
	tr := thrift.NewStreamTransportR(reader)
	err := parquetFileMetaData.Read(thrift.NewTCompactProtocolFactory().GetProtocol(tr))
	if err != nil {
		return nil, nil, err
	}

	columnsNo := len(composer.schemaHandler.ValueColumns)
	columnChunksValuesNo := make([]int, columnsNo)
	pagesNo := make([]byte, 4)
	for i := 0; i < columnsNo; i++ {
		_, err = tr.Read(pagesNo)
		if err != nil {
			return nil, nil, err
		}
		columnChunksValuesNo[i] = int(pagesNo[0]) + (int(pagesNo[1]) << 8) + (int(pagesNo[2]) << 16) + (int(pagesNo[3]) << 24)
	}

	return parquetFileMetaData, columnChunksValuesNo, nil
}

func (composer *Composer) ComposeFile() error {
	err := composer.writeMagicNumber()
	if err != nil {
		return err
	}

	parquetFileMetaData, columnChunksValuesNo, err := composer.getMetaData()
	if err != nil {
		return err
	}

	_, err = composer.writeRowGroup(parquetFileMetaData, columnChunksValuesNo)
	if err != nil {
		return err
	}

	err = composer.writeMetaData(parquetFileMetaData)
	if err != nil {
		return err
	}

	err = composer.writeMagicNumber()
	if err != nil {
		return err
	}

	return nil
}
