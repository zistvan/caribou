package internal

import (
	"bufio"
	"io"
)

const (
	// OpGet is the opcode of a get operation.
	OpGet byte = 0x00
	// OpSetRep is the opcode of a replicated set operation.
	OpSetRep byte = 0x01
	// OpSetLoc is the opcode of a local set operation.
	OpSetLoc byte = 0x1f
	// OpFlush is the opcode of a flush operation.
	OpFlush byte = 0xff
	// OpDelete is the opcode of a delete operation.
	OpDelete byte = 0x2f
	// OpGetCond is the opcode of a conditional get operation.
	OpGetCond byte = 0x40

	initData string = "flushall"
)

// var errNoResult = errors.New("No result provided by the operation")

// Operation holds the information for an operation on the K/V store
// operation.
//
// Key and Value are request specific parameters. OpCode is used
// both for the request as well as the response handling.
// Result is set, depending on the kind of operation, in the
// response handling.
type Operation struct {
	OpCode byte
	Key    []byte
	Value  []byte
	Result []byte
}

// ResponseHandler handles the response of a K/V operation.
//
// handleResponse processes the payload of a received response
// and, if available, sets the result of the operation.
//
// Returns an error if the response was malformed.
type ResponseHandler interface {
	handleResponse(*Operation, *bufio.Reader) error
}

type NoResHandler struct {
}

func (NoResHandler) handleResponse(o *Operation, rd *bufio.Reader) error {
	return nil
}

// EmptyResHandler handles responses that have an empty
// payload and set no specific opcode.
type EmptyResHandler struct {
	SimpleResHandler
}

func (EmptyResHandler) handleResponse(o *Operation, rd *bufio.Reader) error {

	if _, err := rd.ReadBytes(0xff); err != nil {
		return errMalformed
	}

	rheader := make([]byte, 15)

	if _, err := io.ReadFull(rd, rheader); err != nil {
		return err
	}

	if rheader[0] != 0xff {
		return errMalformed
	}

	return nil
}

// SimpleResHandler handles responses that have an empty
// payload, but which contains the same opcode as the preceding
// request.
type SimpleResHandler struct {
}

func (SimpleResHandler) handleResponse(o *Operation, rd *bufio.Reader) error {

	if _, err := rd.ReadBytes(0xff); err != nil {
		return errMalformed
	}

	rheader := make([]byte, 15)

	if _, err := io.ReadFull(rd, rheader); err != nil {
		return errMalformed
	}

	if rheader[0] != 0xff {
		return errMalformed
	}

	if rheader[2] != o.OpCode {
		return errMalformed
	}

	return nil
}

// ValueResHandler handles responses that contain a response value.
type ValueResHandler struct {
}

// var errs = 0

func (ValueResHandler) handleResponse(o *Operation, rd *bufio.Reader) error {

	if _, err := rd.ReadBytes(0xff); err != nil {
		return err
	}

	rheader := make([]byte, 15)

	if _, err := io.ReadFull(rd, rheader); err != nil {
		return err
	}

	//fmt.Printf("Header:\n%s\n", hex.Dump(rheader))

	if rheader[0] != 0xff {
		return errMalformed
	}

	if rheader[2] != o.OpCode {
		return errMalformed
	}

	//--!--test--!--
	// This is the size of the value (number of 64-bit words)
	// HACK: For now we don't use this number because it isn't consistent with the size after the decompression.
	// Instead we use the first 4 bytes from the value to get the decompressed value size.
	sz := (uint32(rheader[4])<<8 | uint32(rheader[3])) << 3

	if sz == 0 {
		return nil
	}

	//fmt.Printf("Size = %d\n", sz)

	//if o.OpCode == OpGet {
	plb := make([]byte, 2)

	if _, err := io.ReadFull(rd, plb); err != nil {
		return err
	}

	//fmt.Printf("Length:\n%v\n", hex.Dump(plb))

	readLen := uint16(plb[1])<<8 | uint16(plb[0])

	//fmt.Printf("readLen = %d\n", readLen)

	if readLen > MaxPkgLen-2 {
		readLen = MaxPkgLen - 2
	}

	rpl := make([]byte, readLen-2)

	if _, err := io.ReadFull(rd, rpl); err != nil {
		return errMalformed
	}

	//fmt.Printf("Data:\n%v\n", hex.Dump(rpl))

	// We should have used sz here, but we don't because of the HACK mentioned above.
	if _, err := rd.Discard(int(8-readLen%8) % 8); err != nil {
		return errMalformed
	}

	o.Result = rpl
	// } else if o.OpCode == OpGetCond {
	// 	plb := make([]byte, 4)

	// 	if _, err := io.ReadFull(rd, plb); err != nil {
	// 		return err
	// 	}

	// 	fmt.Printf("Length:\n%v\n", hex.Dump(plb))

	// 	readLen := uint32(plb[3])<<24 | uint32(plb[2])<<16 | uint32(plb[1])<<8 | uint32(plb[0])

	// 	fmt.Printf("readLen = %d\n", readLen)

	// 	if readLen > MaxPkgLen-2 {
	// 		readLen = MaxPkgLen - 2
	// 	}

	// 	rpl := make([]byte, readLen)

	// 	if _, err := io.ReadFull(rd, rpl); err != nil {
	// 		return errMalformed
	// 	}

	// 	fmt.Printf("Data:\n%v\n", hex.Dump(rpl))

	// 	// We should have used sz here, but we don't because of the HACK mentioned above.
	// 	if _, err := rd.Discard(int(8-(readLen+4)%8) % 8); err != nil {
	// 		return errMalformed
	// 	}

	// 	o.Result = rpl
	// }
	//--!--test--!--

	return nil
}

// NewGetOp initializes an operation type that performs a Get.
func NewGetOp(key []byte) *Operation {
	return &Operation{OpGet, key, nil, nil}
}

// NewSetOp initializes an operation type that performs a local Set.
func NewSetOp(key, value []byte) *Operation {
	return &Operation{OpSetLoc, key, value, nil}
}

// NewSetReplOp initializes an operation that performs a replicated Set.
func NewSetReplOp(key, value []byte) *Operation {
	return &Operation{OpSetRep, key, value, nil}
}

// NewInitOp initializes an operation that performs a Flush.
func NewInitOp() *Operation {
	return &Operation{OpFlush, []byte(initData), nil, nil}
}

// NewDelOp initializes an operation that performs a Delete
func NewDelOp(key []byte) *Operation {
	return &Operation{OpDelete, key, nil, nil}
}

// NewGetCondOp initializes an operation that performs a Conditional Get.
func NewGetCondOp(key, value []byte) *Operation {
	return &Operation{OpGetCond, key, value, nil}
}
