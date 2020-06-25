package transformable

// import (
// 	"strconv"
// )

type Air struct {
	ActivityPeriod *int64 `parquet:"name=ActivityPeriod, type=INT64, repetitiontype=OPTIONAL"`

	OperatingAirline *string `parquet:"name=OperatingAirline, type=UTF8, repetitiontype=OPTIONAL"`

	OperatingAirlineIATACode *string `parquet:"name=OperatingAirlineIATACode, type=UTF8, repetitiontype=OPTIONAL"`

	PublishedAirline *string `parquet:"name=PublishedAirline, type=UTF8, repetitiontype=OPTIONAL"`

	PublishedAirlineIATACode *string `parquet:"name=PublishedAirlineIATACode, type=UTF8, repetitiontype=OPTIONAL"`

	GEOSummary *string `parquet:"name=GEOSummary, type=UTF8, repetitiontype=OPTIONAL"`

	GEORegion *string `parquet:"name=GEORegion, type=UTF8, repetitiontype=OPTIONAL"`

	LandingAircraftType *string `parquet:"name=LandingAircraftType, type=UTF8, repetitiontype=OPTIONAL"`

	AircraftBodyType *string `parquet:"name=AircraftBodyType, type=UTF8, repetitiontype=OPTIONAL"`

	AircraftManufacturer *string `parquet:"name=AircraftManufacturer, type=UTF8, repetitiontype=OPTIONAL"`

	AircraftModel *string `parquet:"name=AircraftModel, type=UTF8, repetitiontype=OPTIONAL"`

	AircraftVersion *string `parquet:"name=AircraftVersion, type=UTF8, repetitiontype=OPTIONAL"`

	LandingCount *int64 `parquet:"name=LandingCount, type=INT64, repetitiontype=OPTIONAL"`

	TotalLandedWeight *int64 `parquet:"name=TotalLandedWeight, type=INT64, repetitiontype=OPTIONAL"`
}

func (air Air) Convert(values []string) Transformable {
	a := Air{}
	// a, _ := strconv.ParseInt(values[0], 10, 64)
	// w, _ := strconv.ParseInt(values[10], 10, 64)
	// m, _ := strconv.ParseFloat(values[11], 64)
	// a.Activity = a
	// a.Airline = values[1]
	// a.AirlineCode = values[2]
	// a.Plubished = values[3]
	// a.PlubishedCode = values[4]
	// a.GEO = values[5]
	// a.Region = values[6]
	// a.ActivityCode = values[7]
	// a.CargoCode = values[8]
	// a.CargoType = values[9]
	// a.CargoWeight = w
	// a.CargoMetric = m
	return a
}
