// Package internal provides methods for the direct communication between the client
// and the K/V store on a network level and defines the protocols of the available
// operations.
//
// This package is not accessible from the perspective of a library user.
package internal

import (
	"bufio"
	"errors"
	"net"
	"sync"
	"time"
)

const (
	// DefTimeout defines the default timeout of read and write operations
	// through the network interface.
	DefTimeout = 5 * time.Second
	// MaxPkgLen is the maximum length of a message to the K/V store.
	// It may later be retrieved dynamically by an info message from the same.
	MaxPkgLen = 8192 //1024 //Modified for parquet
)

var (
	errNotConnected = errors.New("Client is not connected to the server")
	errMalformed    = errors.New("Malformed answer from server")
	numWrPkg        = 0
	reverseBytes    = false
)

// Sender defines an entity that can send messages in order to communicate with
// a connected endpoint.
type Sender interface {
	Send(o *Operation, rh ResponseHandler) error
	SendBulk(ops []*Operation, rh ResponseHandler) error
}

// Connector defines an entity that can maintain a connection to some endpoint
// and close it.
type Connector interface {
	Connect(addr string) error
	Close()
}

// ConnectedSender combines the entities of Sender and Connector.
type ConnectedSender interface {
	Sender
	Connector
}

// CaribouConnection is the implementation of a ConnectedSender for the network
// connection to the FPGA.
//
// The timeout of network operations can be set by hand.
type CaribouConnection struct {
	nc      net.Conn
	buf     *bufio.ReadWriter
	Timeout time.Duration
	sync.Mutex
}

// Connect lets the client connect to it's address and initializes the relevant
// parameters to send and receive data via the TCP connection to Caribou.
//
// Returns an error if the connection can not be established and/or the
// client-specific connection timeout is reached.
func (c *CaribouConnection) Connect(addr string) error {

	conn, err := net.DialTimeout("tcp", addr, c.Timeout)

	if err != nil {
		return err
	}

	c.nc = conn
	c.buf = bufio.NewReadWriter(bufio.NewReader(conn), bufio.NewWriter(conn))

	return nil
}

// Close frees the resources of the connection type and the network connection
// used by it.
func (c *CaribouConnection) Close() {

	//c.Lock()

	//defer c.Unlock()

	if c.nc != nil {
		c.nc.Close()
	}
}

func (c *CaribouConnection) setReadTimeout() error {
	err := c.nc.SetReadDeadline(time.Now().Add(c.Timeout))
	if err != nil {
		return err
	} else {
		return nil
	}
}

func (c *CaribouConnection) setWriteTimeout() error {
	err := c.nc.SetWriteDeadline(time.Now().Add(c.Timeout))
	if err != nil {
		return err
	} else {
		return nil
	}
}

func prepareRequest(o *Operation) ([]byte, error) {

	var pad [8]byte

	var kPad = 0
	var vPad = 0

	var kLen int
	var vLen = 0

	var tk = 0
	var tv = 0

	// TODO Delete Debug
	if reverseBytes {

		m := make([]byte, 8)

		m[0] = o.Key[3]
		m[1] = o.Key[1]
		m[2] = o.Key[2]
		m[3] = o.Key[0]
		m[4] = o.Key[4]
		m[5] = o.Key[5]
		m[6] = o.Key[6]
		m[7] = o.Key[7]

		o.Key = m
	}

	if o.Key != nil && len(o.Key) > 0 {

		kLen = len(o.Key)

		if kLen%8 != 0 {
			kPad = 8 - (kLen % 8)
		}

		tk = kLen + kPad
	}

	if o.Value != nil && len(o.Value) > 0 {

		vLen = len(o.Value) + 2

		if vLen%8 != 0 {
			vPad = 8 - (vLen % 8)
		}

		tv = vLen + vPad
	}

	lb := tk + tv

	b := make([]byte, 16+lb)

	lb /= 8

	header := make([]byte, 0, 16)
	header = append(header, []byte{0xff, 0xff, 0x00, o.OpCode, byte(lb & 0xff), byte((lb >> 8) & 0xff), 0x00, 0x00}...)
	if o.Checkpoint == nil {
		header = append(header, []byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}...)
	} else {
		header = append(header, []byte{0xBB, 0xBB, o.Checkpoint.TokenBucketIdx, o.Checkpoint.TokensEachTick,
			o.Checkpoint.ClkCyclesBeforeTick, o.Checkpoint.MaxBurstSize[0], o.Checkpoint.MaxBurstSize[1], 0x00, 0x00}...)
	}

	copy(b, header)

	if o.Key != nil && len(o.Key) > 0 {
		copy(b[16:], o.Key)
		copy(b[16+len(o.Key):], pad[0:kPad])
	}

	if o.Value != nil && len(o.Value) > 0 {
		b[16+tk+1] = byte((vLen >> 8) & 0xff)
		b[16+tk] = byte(vLen & 0xff)
		copy(b[16+tk+2:], o.Value)
		copy(b[16+tk+vLen:], pad[0:vPad])
	}

	return b, nil
}

// Send sends the given request, containing the K/V operation, over the
// established TCP connection of the client, receives the answer from
// the server and processes it, returning a bool indicating if the
// operation was successfull.
//
// If available for the given request and the operation succeeded,
// the result can be retrieved by the method Result() of the operation type.
//
// Returns an error if the client is not connected at the moment of the call,
// a timeout is reached sending the request or receiving the response,
// or the response is malformed.
func (c *CaribouConnection) Send(o *Operation, rh ResponseHandler) error {

	if c.nc == nil {
		return errNotConnected
	}

	c.Lock()

	req, err := prepareRequest(o)
	if err != nil {
		return err
	}

	err = c.setWriteTimeout()
	if err != nil {
		return err
	}

	if _, err := c.buf.Write(req); err != nil {
		return err
	}

	if err := c.buf.Flush(); err != nil {
		return err
	}

	err = c.setReadTimeout()
	if err != nil {
		return err
	}

	err = rh.handleResponse(o, c.buf.Reader)

	c.Unlock()

	return err
}

// SendBulk performs Send as a bulk operation, sending multiple requests in a row
// and receiving and processing the responses afterwards. It returns a bool
// indicating if all of the operations succeeded or not. Consequently, getting a
// negative result does not mean that not some of the operations were successfully
// performed at the endpoint.
//
// For each request, if available for the given operation, the result
// can be retrieved by the method Result() if the respective operation succeeded.
func (c *CaribouConnection) SendBulk(ops []*Operation, rh ResponseHandler) error {

	if c.nc == nil {
		return errNotConnected
	}

	c.Lock()

	if numWrPkg > 0 {

		var pos int

		for i, o := range ops {

			req, err := prepareRequest(o)
			if err != nil {
				return err
			}

			err = c.setWriteTimeout()
			if err != nil {
				return err
			}

			if _, err := c.buf.Write(req); err != nil {
				return err
			}

			pos++

			if pos == numWrPkg || i == len(ops)-1 {

				if err := c.buf.Flush(); err != nil {
					return err
				}

				for j := 0; j < pos; j++ {

					err = c.setReadTimeout()
					if err != nil {
						return err
					}

					err = rh.handleResponse(ops[i-pos+1+j], c.buf.Reader)
					if err != nil {
						return err
					}

					pos = 0
				}
			}
		}

	} else {

		for _, o := range ops {

			req, err := prepareRequest(o)
			if err != nil {
				return err
			}

			err = c.setWriteTimeout()
			if err != nil {
				return err
			}

			if _, err := c.buf.Write(req); err != nil {
				return err
			}

		}

		if err := c.buf.Flush(); err != nil {
			return err
		}

		for _, o := range ops {

			err := c.setReadTimeout()
			if err != nil {
				return err
			}

			err = rh.handleResponse(o, c.buf.Reader)
			if err != nil {
				return err
			}

		}

	}

	c.Unlock()

	return nil
}
