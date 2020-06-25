package parquet

import "fmt"

type ParquetSchema interface {
	GetSchemaObjectReference() interface{}
}

type Air struct {
	ActivityPeriod           *int64  `parquet:"name=ActivityPeriod, type=INT64, repetitiontype=OPTIONAL"`
	OperatingAirline         *string `parquet:"name=OperatingAirline, type=UTF8, repetitiontype=OPTIONAL"`
	OperatingAirlineIATACode *string `parquet:"name=OperatingAirlineIATACode, type=UTF8, repetitiontype=OPTIONAL"`
	PublishedAirline         *string `parquet:"name=PublishedAirline, type=UTF8, repetitiontype=OPTIONAL"`
	PublishedAirlineIATACode *string `parquet:"name=PublishedAirlineIATACode, type=UTF8, repetitiontype=OPTIONAL"`
	GEOSummary               *string `parquet:"name=GEOSummary, type=UTF8, repetitiontype=OPTIONAL"`
	GEORegion                *string `parquet:"name=GEORegion, type=UTF8, repetitiontype=OPTIONAL"`
	LandingAircraftType      *string `parquet:"name=LandingAircraftType, type=UTF8, repetitiontype=OPTIONAL"`
	AircraftBodyType         *string `parquet:"name=AircraftBodyType, type=UTF8, repetitiontype=OPTIONAL"`
	AircraftManufacturer     *string `parquet:"name=AircraftManufacturer, type=UTF8, repetitiontype=OPTIONAL"`
	AircraftModel            *string `parquet:"name=AircraftModel, type=UTF8, repetitiontype=OPTIONAL"`
	AircraftVersion          *string `parquet:"name=AircraftVersion, type=UTF8, repetitiontype=OPTIONAL"`
	LandingCount             *int64  `parquet:"name=LandingCount, type=INT64, repetitiontype=OPTIONAL"`
	TotalLandedWeight        *int64  `parquet:"name=TotalLandedWeight, type=INT64, repetitiontype=OPTIONAL"`
}

func (obj Air) GetSchemaObjectReference() interface{} {
	return &obj
}

type BankClientMarketingData struct {
	Age       *float64 `parquet:"name=Age, type=DOUBLE, repetitiontype=OPTIONAL"`
	Job       *float64 `parquet:"name=Job, type=DOUBLE, repetitiontype=OPTIONAL"`
	Marital   *float64 `parquet:"name=Marital, type=DOUBLE, repetitiontype=OPTIONAL"`
	Education *float64 `parquet:"name=Education, type=DOUBLE, repetitiontype=OPTIONAL"`
	Default   *float64 `parquet:"name=Default, type=DOUBLE, repetitiontype=OPTIONAL"`
	Balance   *float64 `parquet:"name=Balance, type=DOUBLE, repetitiontype=OPTIONAL"`
	Housing   *float64 `parquet:"name=Housing, type=DOUBLE, repetitiontype=OPTIONAL"`
	Loan      *float64 `parquet:"name=Loan, type=DOUBLE, repetitiontype=OPTIONAL"`
	Contact   *float64 `parquet:"name=Contact, type=DOUBLE, repetitiontype=OPTIONAL"`
	Day       *float64 `parquet:"name=Day, type=DOUBLE, repetitiontype=OPTIONAL"`
	Month     *float64 `parquet:"name=Month, type=DOUBLE, repetitiontype=OPTIONAL"`
	Duration  *float64 `parquet:"name=Duration, type=DOUBLE, repetitiontype=OPTIONAL"`
	Campaign  *float64 `parquet:"name=Campaign, type=DOUBLE, repetitiontype=OPTIONAL"`
	Pdays     *float64 `parquet:"name=Pdays, type=DOUBLE, repetitiontype=OPTIONAL"`
	Previous  *float64 `parquet:"name=Previous, type=DOUBLE, repetitiontype=OPTIONAL"`
	Poutcome  *float64 `parquet:"name=Poutcome, type=DOUBLE, repetitiontype=OPTIONAL"`
	Y         *float64 `parquet:"name=Y, type=DOUBLE, repetitiontype=OPTIONAL"`
}

func (obj BankClientMarketingData) GetSchemaObjectReference() interface{} {
	return &obj
}

func (obj BankClientMarketingData) String() string {
	return fmt.Sprintf("BankClientMarketingData{Age:%f, Job:%f, Marital:%f, Education:%f, Default:%f, Balance:%f, Housing:%f, Loan:%f, "+
		"Contact:%f, Day:%f, Month:%f, Duration:%f, Campaign:%f, Pdays:%f, Previous:%f, Poutcome:%f, Y:%f}", *obj.Age, *obj.Job, *obj.Marital,
		*obj.Education, *obj.Default, *obj.Balance, *obj.Housing, *obj.Loan, *obj.Contact, *obj.Day, *obj.Month, *obj.Duration, *obj.Campaign,
		*obj.Pdays, *obj.Previous, *obj.Poutcome, *obj.Y)
}

type PimaIndiansDiabetesData struct {
	Pregnancies              *float64 `parquet:"name=Pregnancies, type=DOUBLE, repetitiontype=OPTIONAL"`
	Glucose                  *float64 `parquet:"name=Glucose, type=DOUBLE, repetitiontype=OPTIONAL"`
	BloodPressure            *float64 `parquet:"name=BloodPressure, type=DOUBLE, repetitiontype=OPTIONAL"`
	SkinThickness            *float64 `parquet:"name=SkinThickness, type=DOUBLE, repetitiontype=OPTIONAL"`
	Insulin                  *float64 `parquet:"name=Insulin, type=DOUBLE, repetitiontype=OPTIONAL"`
	BMI                      *float64 `parquet:"name=BMI, type=DOUBLE, repetitiontype=OPTIONAL"`
	DiabetesPedigreeFunction *float64 `parquet:"name=DiabetesPedigreeFunction, type=DOUBLE, repetitiontype=OPTIONAL"`
	Age                      *float64 `parquet:"name=Age, type=DOUBLE, repetitiontype=OPTIONAL"`
	Outcome                  *float64 `parquet:"name=Outcome, type=DOUBLE, repetitiontype=OPTIONAL"`
}

func (obj PimaIndiansDiabetesData) GetSchemaObjectReference() interface{} {
	return &obj
}

func (obj PimaIndiansDiabetesData) String() string {
	return fmt.Sprintf("PimaIndiansDiabetesData{Pregnancies:%f, Glucose:%f, BloodPressure:%f, SkinThickness:%f, Insulin:%f, BMI:%f, DiabetesPedigreeFunction:%f, Age:%f, "+
		"Outcome:%f}", *obj.Pregnancies, *obj.Glucose, *obj.BloodPressure, *obj.SkinThickness, *obj.Insulin, *obj.BMI, *obj.DiabetesPedigreeFunction, *obj.Age,
		*obj.Outcome)
}
