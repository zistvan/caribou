package main

import (
	//"fmt"
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	"strings"
	"time"
)

func bProc() (map[string]int64, float64, float64, float64) {
	m := make(map[string]int64)

	start := time.Now()

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

	t1 := float64(time.Since(start).Nanoseconds()) / 1e3
	prep := time.Now()

	rows, _, err := p.GetAllRows(key)
	if err != nil {
		log.Fatalf("Error get all rows: %s\n", err)
	}

	t2 := float64(time.Since(prep).Nanoseconds()) / 1e3
	proc := time.Now()

	for i := 0; i < len(rows); i++ {
		if strings.Contains(rows[i][5].(string), "International") && strings.Contains(rows[i][7].(string), "Freighter") {
			//fmt.Printf("%v\n", rows[i])
			m[rows[i][2].(string)] += rows[i][13].(int64)
		}
	}
	t3 := float64(time.Since(proc).Nanoseconds()) / 1e3

	return m, t1, t2, t3
}
