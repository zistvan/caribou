package main

import (
	"flag"
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	"strings"
)

func main() {
	var (
		err         error
		inFilePath  string
		hostAddress string
		memcached   bool
	)

	flag.BoolVar(&memcached, "m", false, "If set use memcached, default is false")
	flag.StringVar(&hostAddress, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&inFilePath, "f", "bank_labeled.parquet", "Path to the .parquet input file.")
	flag.Parse()

	var client *ops.Client
	if memcached {
		client = ops.NewTestClient(hostAddress)
	} else {
		client = ops.NewClient(hostAddress)
	}

	err = client.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer client.Disconnect()

	var schemaStruct parquet.Schema
	if strings.Contains(inFilePath, "bank") {
		schemaStruct = parquet.BankClientMarketingData{}
	} else if strings.Contains(inFilePath, "diabetes") {
		schemaStruct = parquet.PimaIndiansDiabetesData{}
	}

	p, err := parquet.NewProcessor(client, schemaStruct)
	if err != nil {
		log.Fatalf("Error new processor: %s\n", err)
	}

	key := []byte("ttt")

	err = p.StoreFile(key, inFilePath)
	if err != nil {
		log.Fatalf("Error store file: %s\n", err)
	}

	err = p.GetFile(key, "./out.parquet")
	if err != nil {
		log.Fatalf("Error get file: %s\n", err)
	}
}
