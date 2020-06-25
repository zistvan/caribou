package main

import (
	"log"
	"multes_client_library_priv/ops"
	"multes_client_library_priv/parquet"
	"strings"
	"time"
)

func bProcCF() (map[string]int64, float64, float64, float64) {
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

	p.DisableColumn(0)
	p.DisableColumn(1)
	p.DisableColumn(3)
	p.DisableColumn(4)
	p.DisableColumn(6)
	p.DisableColumn(8)
	p.DisableColumn(9)
	p.DisableColumn(10)
	p.DisableColumn(11)
	p.DisableColumn(12)

	p.SetColumnFilter(5, func(val []byte) bool { return strings.Contains(string(val), "International") })
	p.SetColumnFilter(7, func(val []byte) bool { return strings.Contains(string(val), "Freighter") })

	rows, _, err := p.GetAllRows(key)
	if err != nil {
		log.Fatalf("Error get all rows: %s\n", err)
	}

	t2 := float64(time.Since(prep).Nanoseconds()) / 1e3
	proc := time.Now()

	for i := 0; i < len(rows); i++ {
		m[rows[i][0].(string)] += rows[i][3].(int64)
	}
	t3 := float64(time.Since(proc).Nanoseconds()) / 1e3

	return m, t1, t2, t3
}
