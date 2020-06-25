package main

import (
	"bytes"
	"encoding/binary"
	"io/ioutil"
	"log"
)

var (
	headerSize   = 49
	pageSize     = 16
	outFilePaths = []string{"page0_synth", "page1_synth", "page2_synth"}
)

func main() {
	for i := 0; i < len(outFilePaths); i++ {
		var page []byte
		for j := 0; j < headerSize; j++ {
			page = append(page, byte('a'))
		}
		for currentSize := 0; currentSize < pageSize; currentSize += 8 {
			nr := float64(1.0 + i)
			nrBuf := new(bytes.Buffer)
			err := binary.Write(nrBuf, binary.LittleEndian, nr)
			if err != nil {
				log.Fatal(err)
			}
			page = append(page, nrBuf.Bytes()...)
		}
		err := ioutil.WriteFile(outFilePaths[i], page, 0644)
		if err != nil {
			log.Fatal(err)
		}
	}
}
