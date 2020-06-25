package transformable

type Schema int

const (
	Airport         Schema = 0
	Restaurant      Schema = 1
	Police          Schema = 2
	AirportComplete Schema = 3
	TestSchema      Schema = 4
)

type Transformable interface {
	Convert([]string) Transformable
}

func GetType(s Schema) Transformable {
	switch s {
	case Airport:
		return new(Fly)
	case Restaurant:
		return new(RestaurantScore)
	case Police:
		return new(PoliceReport)
	case AirportComplete:
		return new(Air)
	case TestSchema:
		return new(Test)
	}
	return nil
}
