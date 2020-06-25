package internal

import (
	"encoding/base64"

	"github.com/bradfitz/gomemcache/memcache"
)

type MemcachedConnection struct {
	c *memcache.Client
}

func (m *MemcachedConnection) Connect(addr string) error {

	m.c = memcache.New(addr)

	return nil
}

func (m *MemcachedConnection) Close() {
}

func (m *MemcachedConnection) Send(o *Operation, rh ResponseHandler) error {

	switch o.OpCode {

	case OpGet:
		it, err := m.c.Get(base64.StdEncoding.EncodeToString(o.Key))

		if err != nil {
			return err
		}

		o.Result = it.Value

	case OpSetLoc, OpSetRep:

		it := memcache.Item{Key: base64.StdEncoding.EncodeToString(o.Key), Value: o.Value}

		if err := m.c.Set(&it); err != nil {
			return err
		}

	case OpDelete:

		if err := m.c.Delete(string(o.Key)); err != nil {
			return err
		}

	case OpFlush:

		if err := m.c.FlushAll(); err != nil {
			return err
		}
	}

	return nil
}

func (m *MemcachedConnection) SendBulk(ops []*Operation, rh ResponseHandler) error {
	var err error

	keys := make([]string, 0, len(ops))

	for _, o := range ops {

		if o.OpCode == OpGet {
			keys = append(keys, base64.StdEncoding.EncodeToString(o.Key))
		} else {
			err = m.Send(o, rh)
			if err != nil {
				return err
			}
		}
	}

	if len(keys) > 0 {

		res, err := m.c.GetMulti(keys)
		if err != nil {
			return err
		}

		for _, o := range ops {

			o.Result = res[base64.StdEncoding.EncodeToString(o.Key)].Value
		}
	}

	return nil
}
