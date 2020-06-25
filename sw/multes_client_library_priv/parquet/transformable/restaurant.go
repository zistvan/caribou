package transformable

import (
	"strconv"
)

type RestaurantScore struct {
	Business_id           string `parquet:"name=Business_id, type=UTF8"`
	Business_name         string `parquet:"name=Business_name, type=UTF8"`
	Business_address      string `parquet:"name=Business_address, type=UTF8"`
	Business_city         string `parquet:"name=Business_city, type=UTF8"`
	Business_state        string `parquet:"name=Business_state, type=UTF8"`
	Business_postal_code  int64  `parquet:"name=Business_postal_code, type=INT64"`
	Business_latitude     int64  `parquet:"name=Business_latitude, type=INT64"`
	Business_longitude    int64  `parquet:"name=Business_longitude, type=INT64"`
	Business_location     string `parquet:"name=Business_location, type=UTF8"`
	Business_phone_number string `parquet:"name=Business_phone_number, type=UTF8"`
	Inspection_id         string `parquet:"name=Inspection_id, type=UTF8"`
	Inspection_score      int64  `parquet:"name=Inspection_score, type=INT64"`
	Inspection_type       string `parquet:"name=Inspection_type, type=UTF8"`
	Inspection_date       string `parquet:"name=Inspection_date, type=UTF8"`
	Violation_id          string `parquet:"name=Violation_id, type=UTF8"`
	Violation_description string `parquet:"name=Violation_description, type=UTF8"`
	Risk_category         string `parquet:"name=Risk_category, type=UTF8"`
}

func (self RestaurantScore) Convert(values []string) Transformable {
	res := RestaurantScore{}
	postalcode, _ := strconv.ParseInt(values[5], 10, 64)
	lat, _ := strconv.ParseInt(values[6], 10, 64)
	log, _ := strconv.ParseInt(values[7], 10, 64)
	score, _ := strconv.ParseInt(values[11], 10, 64)

	res.Business_id = values[0]
	res.Business_name = values[1]
	res.Business_address = values[2]
	res.Business_city = values[3]
	res.Business_state = values[4]
	res.Business_postal_code = postalcode
	res.Business_latitude = lat
	res.Business_longitude = log
	res.Business_location = values[8]
	res.Business_phone_number = values[9]
	res.Inspection_id = values[10]
	res.Inspection_score = score
	res.Inspection_type = values[12]
	res.Inspection_date = values[13]
	res.Violation_id = values[14]
	res.Violation_description = values[15]
	res.Risk_category = values[16]
	return res
}
