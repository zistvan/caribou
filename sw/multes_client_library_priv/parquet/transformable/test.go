package transformable

import (
	"strconv"
)

type Test struct {
	Id *int64 `parquet:"name=Id, type=INT64, repetitiontype=OPTIONAL"`

	Name *string `parquet:"name=Name, type=UTF8, repetitiontype=OPTIONAL"`
}

func (test Test) Convert(values []string) Transformable {
	t := Test{}
	id, err := strconv.ParseInt(values[0], 10, 64)
	if err != nil {
		return nil
	}
	t.Id = &id
	t.Name = &values[1]
	return t
}
