package main

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"io/ioutil"
	"log"
	"os/exec"
	"strconv"
	"strings"
)

var (
	matrix      = []float64{0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3}
	headerSize  = 49
	inFilePaths = []string{"page0", "page1", "page2"}
	pageSize    = 4096
	repeatNo    = 32
)

func main() {
	pageHeaders := make([]string, len(inFilePaths))
	pageDatas := make([]string, len(inFilePaths))
	for i := 0; i < len(inFilePaths); i++ {
		cmd := exec.Command("xxd", "-p", "-g 0", "-c 64", inFilePaths[i])
		var pageHexdump bytes.Buffer
		cmd.Stdout = &pageHexdump
		err := cmd.Run()
		if err != nil {
			log.Fatal(err)
		}

		pageHexdumpString := strings.ReplaceAll(pageHexdump.String(), "\n", "")

		pageHeaders[i] = pageHexdumpString[0 : headerSize*2]

		pageDatas[i] = pageHexdumpString[headerSize*2:]
	}

	var matVecData string
	pageIndices := make([]int, len(inFilePaths))
	for currentSize := 0; currentSize < pageSize; currentSize += 8 {
		for i := 0; i < len(inFilePaths); i++ {
			matVecData += pageDatas[i][pageIndices[i] : pageIndices[i]+16]
			if pageIndices[i]+16 > len(pageDatas[i])-16 {
				pageIndices[i] = 0
			} else {
				pageIndices[i] += 16
			}
		}
		matVecData += "\n"
	}
	err := ioutil.WriteFile("./inMatrixVectorMultiplication"+strconv.Itoa(pageSize)+".txt", []byte(matVecData), 0644)
	if err != nil {
		log.Fatal(err)
	}

	var rotationData string
	pageLength := uint16(2 + headerSize + pageSize)
	pageLengthBytes := make([]byte, 2)
	binary.LittleEndian.PutUint16(pageLengthBytes, pageLength)
	pageLengthString := hex.EncodeToString(pageLengthBytes)
	rotationPageData := make([]string, len(inFilePaths))
	for currentRepeatNo := 0; currentRepeatNo < repeatNo; currentRepeatNo++ {
		for i := 0; i < len(inFilePaths); i++ {
			rotationPageData[i] = pageLengthString + pageHeaders[i]
			pageIndices[i] = 0
			for currentSize := 0; currentSize < pageSize; currentSize += 8 {
				rotationPageData[i] += pageDatas[i][pageIndices[i] : pageIndices[i]+16]
				if pageIndices[i]+16 > len(pageDatas[i])-16 {
					pageIndices[i] = 0
				} else {
					pageIndices[i] += 16
				}
			}
			for j := 0; j < len(rotationPageData[i]); j += 128 {
				if j+128 >= len(rotationPageData[i]) {
					rotationData += "1" + rotationPageData[i][j:]
					for k := 0; k < 128-(len(rotationPageData[i])-j); k++ {
						rotationData += "0"
					}
					rotationData += "\n"
				} else {
					rotationData += "0" + rotationPageData[i][j:j+128] + "\n"
				}
			}
		}
	}
	err = ioutil.WriteFile("./inRotationModule"+strconv.Itoa(pageSize)+".txt", []byte(rotationData), 0644)
	if err != nil {
		log.Fatal(err)
	}

	var multesData string
	resetData := "0050\n0000\n0FFFF00FF01000100\n0F00BA20000000000\n11000000000000001\n0600\n0000\n"
	waitData := "0100\n0000\n"
	multesData = resetData

	// baga aici pt set rot mat si apoi pt get
	multesPageSetData := "FFFF001F0B000000000000000000000099999999999999994A00"
	var matrixBytes []byte
	for _, v := range matrix {
		nrBuf := new(bytes.Buffer)
		err := binary.Write(nrBuf, binary.LittleEndian, v)
		if err != nil {
			log.Fatal(err)
		}
		matrixBytes = append(matrixBytes, nrBuf.Bytes()...)
	}
	multesPageSetData += hex.EncodeToString(matrixBytes) + "000000000000"

	payloadLength := pageLength/8 + 1
	if pageLength%8 != 0 {
		payloadLength++
	}
	payloadLengthBytes := make([]byte, 2)
	binary.LittleEndian.PutUint16(payloadLengthBytes, payloadLength)
	payloadLengthString := hex.EncodeToString(payloadLengthBytes)
	for i := 0; i < len(inFilePaths); i++ {
		if i == 0 {
			multesPageSetData += "FFFF001F" + payloadLengthString + "00000000000000000000"
		} else {
			multesPageSetData = "FFFF001F" + payloadLengthString + "00000000000000000000"
		}
		for j := 0; j < 16; j++ {
			multesPageSetData += strconv.Itoa(i + 1)
		}
		multesPageSetData += rotationPageData[i]
		for j := 0; j < len(multesPageSetData); j += 16 {
			if j+16 >= len(multesPageSetData) {
				if i == len(inFilePaths)-1 {
					multesData += "1" + multesPageSetData[j:]
				} else {
					multesData += "0" + multesPageSetData[j:]
				}
				for k := 0; k < 16-(len(multesPageSetData)-j); k++ {
					multesData += "0"
				}
				multesData += "\n"
			} else {
				multesData += "0" + multesPageSetData[j:j+16] + "\n"
			}
		}
	}
	multesData += waitData

	multesData += "0FFFF004002000000\n00000000000000000\n09999999999999999\n10300FE0000000000\n"

	multesData += waitData
	for currentRepeatNo := 0; currentRepeatNo < repeatNo; currentRepeatNo++ {
		for i := 0; i < len(inFilePaths); i++ {
			multesPageGetData := "0FFFF004002000000\n00000000000000000\n0"
			for j := 0; j < 16; j++ {
				multesPageGetData += strconv.Itoa(i + 1)
			}
			if i == len(inFilePaths)-1 && currentRepeatNo == repeatNo-1 {
				multesPageGetData += "\n10300FF0000000000\n"
			} else {
				multesPageGetData += "\n00300FF0000000000\n"
			}
			multesData += multesPageGetData
		}
	}
	multesData += waitData
	err = ioutil.WriteFile("./session-event-in"+strconv.Itoa(pageSize)+".txt", []byte(multesData), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
