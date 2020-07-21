package main

import (
	"flag"
	"log"
	"strconv"

	"multes_client_library_priv/ops"

	"multes_client_library_priv/parquet"
)

var (
	addr        string
	file        string
	datasetSize int
	ky          string
	key         []byte
	memcached   bool
	schema      parquet.Air
)

func main() {
	flag.StringVar(&addr, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&file, "f", "fly.parquet", "Parquet file path")
	flag.IntVar(&datasetSize, "s", 0, "Dateset size in k rows")
	flag.StringVar(&ky, "k", "test", "Key value at which to put the file")
	flag.BoolVar(&memcached, "m", false, "If set use memcached, default is false")
	flag.Parse()

	if datasetSize != 0 {
		file = "fly" + strconv.Itoa(datasetSize) + ".parquet"
	}

	key = []byte(ky)

	var c *ops.Client
	if memcached {
		c = ops.NewTestClient(addr)
	} else {
		c = ops.NewClient(addr)
	}

	err := c.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer c.Disconnect()

	p, err := parquet.NewProcessor(c, schema)
	if err != nil {
		log.Fatalf("Error new processor: %s\n", err)
	}

	err = p.StoreFile(key, file)
	if err != nil {
		log.Fatalf("Error store file: %s\n", err)
	}
}
