package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"io/ioutil"
	"log"

	"multes_client_library_priv/ops"

	"github.com/golang/snappy"
)

func main() {
	var (
		addr      string
		filePath  string
		ky        string
		key       []byte
		memcached bool
		err       error
	)

	flag.StringVar(&addr, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&filePath, "f", "in.txt", "File path from where to read data to be set.")
	flag.StringVar(&ky, "k", "test", "Key value.")
	flag.BoolVar(&memcached, "m", false, "If set use memcached, default is false")
	flag.Parse()

	key = []byte(ky)

	var c *ops.Client
	if memcached {
		c = ops.NewTestClient(addr)
	} else {
		c = ops.NewClient(addr)
	}

	err = c.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer c.Disconnect()

	uncompressed, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Error read file: %s\n", err)
	}

	compressed := snappy.Encode(nil, uncompressed)

	err = c.Set(key, compressed)
	if err != nil {
		log.Fatalf("Error set: %s\n", err)
	}

	valGet, err := c.Get(key)
	if err != nil {
		log.Fatalf("Error get: %s\n", err)
	}

	fmt.Printf("Raw value:\n%s\n", hex.Dump(valGet))

	valGetCond, err := c.GetCond(key, []byte{1})
	if err != nil {
		log.Fatalf("Error getCond: %s\n", err)
	}

	fmt.Printf("Decompressed value:\n%s\n", hex.Dump(valGetCond))
}
