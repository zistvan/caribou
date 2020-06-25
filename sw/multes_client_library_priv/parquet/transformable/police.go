package transformable

import (
	"strconv"
)

type PoliceReport struct {
	IncidntNum string `parquet:"name=IncidntNum, type=UTF8"`
	Category   string `parquet:"name=Category, type=UTF8"`
	Descript   string `parquet:"name=Descript, type=UTF8"`
	Dayofweek  string `parquet:"name=DayOfWeek, type=UTF8"`
	Date       string `parquet:"name=Date, type=UTF8"`
	Time       string `parquet:"name=Time, type=UTF8"`
	Pddistrict string `parquet:"name=PdDistrict, type=UTF8"`
	Resolution string `parquet:"name=Resolution, type=UTF8"`
	Address    string `parquet:"name=Address, type=UTF8"`
	X          int64  `parquet:"name=X, type=INT64"`
	Y          int64  `parquet:"name=Y, type=INT64"`
	Location   string `parquet:"name=Location, type=UTF8"`
	Pdid       int64  `parquet:"name=PdId, type=INT64"`
}

func (self PoliceReport) Convert(values []string) Transformable {
	pol := PoliceReport{}
	x, _ := strconv.ParseInt(values[9], 10, 64)
	y, _ := strconv.ParseInt(values[10], 10, 64)

	p, _ := strconv.ParseInt(values[12], 10, 64)

	pol.IncidntNum = values[0]
	pol.Category = values[1]
	pol.Descript = values[2]
	pol.Dayofweek = values[3]
	pol.Date = values[4]
	pol.Time = values[5]
	pol.Pddistrict = values[6]
	pol.Resolution = values[7]
	pol.Address = values[8]
	pol.X = x
	pol.Y = y
	pol.Location = values[11]
	pol.Pdid = p
	return pol
}
