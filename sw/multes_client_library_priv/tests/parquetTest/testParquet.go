package main

import (
	"flag"
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	//"strings"
	//"encoding/hex"
	//"fmt"
)

func testParquet() {
	log.Print("Start test\n\n")

	var (
		err  error
		file string
		addr string
	)
	flag.StringVar(&file, "f", "fly.parquet", "Input file that is set in the K/V store")
	flag.StringVar(&addr, "h", "localhost:11211", "The address of the server (host:port)")
	flag.Parse()

	c := ops.NewTestClient(addr)

	err = c.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer c.Disconnect()

	var schema parquet.BankClientMarketingData

	p, err := parquet.NewProcessor(c, schema)
	if err != nil {
		log.Fatalf("Error new processor: %s\n", err)
	}

	key := []byte("test")

	err = p.StoreFile(key, file)
	if err != nil {
		log.Fatalf("Error store file: %s\n", err)
	}

	err = p.GetFile(key, "./out.parquet")
	if err != nil {
		log.Fatalf("Error get file: %s\n", err)
	}

	// _, _, err = p.GetMetaData(key)
	// if err != nil {
	// 	log.Fatalf("Error get meta: %s\n", err)
	// }
	// //log.Printf("%v\n\n", meta)

	// p.DisableColumn(0)
	// p.DisableColumn(1)
	// p.DisableColumn(2)
	// p.DisableColumn(3)
	// p.DisableColumn(4)
	// p.DisableColumn(5)
	// p.DisableColumn(6)
	// p.DisableColumn(7)
	// p.DisableColumn(8)
	// p.DisableColumn(9)
	// p.DisableColumn(10)
	// p.DisableColumn(11)
	// p.DisableColumn(12)
	// p.DisableColumn(13)
	// //p.SetColumnFilter(1, func(val []byte) bool { return strings.Contains(string(val), "aii") })
	// p.SetColumnFilter(5, func(val []byte) bool { return strings.Contains(string(val), "International") })
	// p.SetColumnFilter(8, func(val []byte) bool { return strings.Contains(string(val), "Mail") })

	rows, types, err := p.GetAllRows(key)
	if err != nil {
		log.Fatalf("Error GetAllRows: %s\n", err)
	}
	log.Printf("%v %d\n\n%v\n\n", rows, len(rows), types)

	// rowBatch, types, cont, err := p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// for {

	// }

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)

	// rowBatch, types, cont, err = p.GetRowBatch(key)
	// if err != nil {
	// 	log.Fatalf("Error get row batch: %s\n", err)
	// }
	// log.Printf("%v %d\n\n%v\n\n%v\n\n", rowBatch, len(rowBatch), types, cont)
}
