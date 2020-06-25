package main

import (
	//"fmt"
	"log"
	"multes_client_library_priv/parquet/transformable"
	"strings"
	"time"

	"github.com/xitongsys/parquet-go/ParquetFile"
	"github.com/xitongsys/parquet-go/ParquetReader"
)

func bLib() (map[string]int64, float64, float64, float64) {
	m := make(map[string]int64)
	var err error

	start := time.Now()

	fr, err := ParquetFile.NewLocalFileReader(file)
	if err != nil {
		log.Fatalf("Error file: %v\n", err)
		return nil, 0, 0, 0
	}
	pr, err := ParquetReader.NewParquetReader(fr, schema.GetSchemaObjectReference(), 8)
	if err != nil {
		log.Fatalf("Error reader: %v\n", err)
		return nil, 0, 0, 0
	}

	t1 := float64(time.Since(start).Nanoseconds()) / 1e3
	prep := time.Now()

	n := int(pr.GetNumRows())

	f := make([]transformable.Air, n)

	err = pr.Read(&f)
	if err != nil {
		log.Fatalf("Error read: %v\n", err)
		return nil, 0, 0, 0
	}

	t2 := float64(time.Since(prep).Nanoseconds()) / 1e3
	proc := time.Now()

	for i := 0; i < n; i++ {
		if strings.Contains(*f[i].GEOSummary, "International") && strings.Contains(*f[i].LandingAircraftType, "Freighter") {
			m[*f[i].OperatingAirlineIATACode] += *f[i].TotalLandedWeight
		}
	}
	t3 := float64(time.Since(proc).Nanoseconds()) / 1e3

	return m, t1, t2, t3
}
