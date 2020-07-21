package main

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"multes_client_library_priv/ops"
	"strconv"
)

var matrix = []float64{0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3}

func main() {
	var (
		err         error
		addr        string
		inFilePaths = []string{"page0", "page1", "page2"}
	)

	flag.StringVar(&addr, "h", "localhost:11211", "The address of the server (host:port)")
	flag.Parse()

	c := ops.NewClient(addr)

	err = c.Connect()
	if err != nil {
		log.Fatalf("Error connect: %s\n", err)
	}
	defer c.Disconnect()

	for i := 0; i < 3; i++ {
		pageData, err := ioutil.ReadFile(inFilePaths[i])
		if err != nil {
			log.Fatalf("Error read file: %s\n", err)
		}

		err = c.Set([]byte(strconv.Itoa(i+1)), pageData)
		if err != nil {
			log.Fatalf("Error set: %s\n", err)
		}
	}

	var matrixBytes []byte
	for _, v := range matrix {
		nrBuf := new(bytes.Buffer)
		err := binary.Write(nrBuf, binary.LittleEndian, v)
		if err != nil {
			log.Fatal(err)
		}
		matrixBytes = append(matrixBytes, nrBuf.Bytes()...)
	}
	err = c.Set([]byte("rotmat"), matrixBytes)
	if err != nil {
		log.Fatalf("Error set: %s\n", err)
	}

	err = c.GetRotationMatrix()
	if err != nil {
		log.Fatalf("Error GetRotationMatrix: %s\n", err)
	}

	results, err := c.GetPerturbed([][]byte{[]byte(strconv.Itoa(1)), []byte(strconv.Itoa(2)), []byte(strconv.Itoa(3))})
	if err != nil {
		log.Fatalf("Error GetPerturbed: %s\n", err)
	}

	for i := 0; i < 3; i++ {
		fmt.Printf("GetCond value[%d]:\n%s\n", i, hex.Dump(results[i]))
	}

	// if !memcached {
	// 	valGetCond, err := c.GetCond([]byte("rotmat"), []byte{0xFE})
	// 	if err != nil {
	// 		log.Fatalf("Error getCond: %s\n", err)
	// 	}
	// 	fmt.Printf("GetCond value:\n%s\n", hex.Dump(valGetCond))
	// }

	// for i := 0; i < len(inFilePaths); i++ {
	// 	if memcached {
	// 		valGet, err := c.Get([]byte(strconv.Itoa(i + 1)))
	// 		if err != nil {
	// 			log.Fatalf("Error get: %s\n", err)
	// 		}
	// 		fmt.Printf("Get value:\n%s\n", hex.Dump(valGet))
	// 	} else {
	// 		valGetCond, err := c.GetCond([]byte(strconv.Itoa(i+1)), []byte{0xFF})
	// 		if err != nil {
	// 			log.Fatalf("Error getCond: %s\n", err)
	// 		}
	// 		fmt.Printf("GetCond value:\n%s\n", hex.Dump(valGetCond))
	// 	}
	// }
}
