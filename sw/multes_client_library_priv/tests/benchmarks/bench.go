package main

import (
	"flag"
	"fmt"
	"multes_client_library_priv/parquet"
	"strconv"
)

var (
	addr        string
	file        string
	datasetSize int
	ky          string
	key         []byte
	memcached   bool
	repeatsNo   int
	schema      parquet.Air
	m           = make(map[string]int64)
)

func main() {
	flag.StringVar(&addr, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&file, "f", "fly.parquet", "Parquet file path")
	flag.IntVar(&repeatsNo, "r", 100, "Number of times the test is repeated in order to give average time")
	flag.IntVar(&datasetSize, "s", 0, "Dateset size in k rows")
	flag.StringVar(&ky, "k", "test", "Key value at which to put the file")
	flag.BoolVar(&memcached, "m", false, "If set use memcached, default is false")
	flag.Parse()

	if datasetSize != 0 {
		file = "fly" + strconv.Itoa(datasetSize) + ".parquet"
	}

	key = []byte(ky)

	// c := ops.NewTestClient(addr)

	// err := c.Connect()
	// if err != nil {
	// 	log.Fatalf("Error connect: %s\n", err)
	// }
	// defer c.Disconnect()

	// p, err := parquet.NewProcessor(c, schema)
	// if err != nil {
	// 	log.Fatalf("Error new processor: %s\n", err)
	// }

	// err = p.StoreFile(key, file)
	// if err != nil {
	// 	log.Fatalf("Error store file: %s\n", err)
	// }

	var (
		s1 float64
		s2 float64
		s3 float64
		t1 float64
		t2 float64
		t3 float64
	)

	s1, s2, s3 = 0, 0, 0
	for i := 0; i < repeatsNo; i++ {
		m, t1, t2, t3 = bLib()
		s1 += t1
		s2 += t2
		s3 += t3
	}
	s1 /= float64(repeatsNo)
	s2 /= float64(repeatsNo)
	s3 /= float64(repeatsNo)
	fmt.Printf("%.6f,%.6f,%.6f,%d\n", s1, s2, s3, len(m))

	s1, s2, s3 = 0, 0, 0
	for i := 0; i < repeatsNo; i++ {
		m, t1, t2, t3 = bProc()
		s1 += t1
		s2 += t2
		s3 += t3
	}
	s1 /= float64(repeatsNo)
	s2 /= float64(repeatsNo)
	s3 /= float64(repeatsNo)
	fmt.Printf("%.6f,%.6f,%.6f,%d\n", s1, s2, s3, len(m))

	s1, s2, s3 = 0, 0, 0
	for i := 0; i < repeatsNo; i++ {
		m, t1, t2, t3 = bProcC()
		s1 += t1
		s2 += t2
		s3 += t3
	}
	s1 /= float64(repeatsNo)
	s2 /= float64(repeatsNo)
	s3 /= float64(repeatsNo)
	fmt.Printf("%.6f,%.6f,%.6f,%d\n", s1, s2, s3, len(m))

	s1, s2, s3 = 0, 0, 0
	for i := 0; i < repeatsNo; i++ {
		m, t1, t2, t3 = bProcCF()
		s1 += t1
		s2 += t2
		s3 += t3
	}
	s1 /= float64(repeatsNo)
	s2 /= float64(repeatsNo)
	s3 /= float64(repeatsNo)
	fmt.Printf("%.6f,%.6f,%.6f,%d\n--------------------------\n", s1, s2, s3, len(m))
}
