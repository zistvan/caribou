package transformable

import (
	"strconv"
)

type Fly struct {
	Activity      int64   `parquet:"name=Activity, type=INT64"`
	Airline       string  `parquet:"name=Airline, type=UTF8"`
	AirlineCode   string  `parquet:"name=AirlineCode, type=UTF8"`
	Plubished     string  `parquet:"name=Plubished, type=UTF8"`
	PlubishedCode string  `parquet:"name=PlubishedCode, type=UTF8"`
	GEO           string  `parquet:"name=GEO, type=UTF8"`
	Region        string  `parquet:"name=Region, type=UTF8"`
	ActivityCode  string  `parquet:"name=ActivityCode, type=UTF8"`
	CargoCode     string  `parquet:"name=CargoCode, type=UTF8"`
	CargoType     string  `parquet:"name=CargoType, type=UTF8"`
	CargoWeight   int64   `parquet:"name=CargoWeight, type=INT64"`
	CargoMetric   float64 `parquet:"name=CargoMetric, type=DOUBLE"`
}

func (self Fly) Convert(values []string) Transformable {
	f := Fly{}
	a, _ := strconv.ParseInt(values[0], 10, 64)
	w, _ := strconv.ParseInt(values[10], 10, 64)
	m, _ := strconv.ParseFloat(values[11], 64)
	f.Activity = a
	f.Airline = values[1]
	f.AirlineCode = values[2]
	f.Plubished = values[3]
	f.PlubishedCode = values[4]
	f.GEO = values[5]
	f.Region = values[6]
	f.ActivityCode = values[7]
	f.CargoCode = values[8]
	f.CargoType = values[9]
	f.CargoWeight = w
	f.CargoMetric = m
	return f

}
