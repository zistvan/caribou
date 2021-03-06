// Package ops provides CRUD operations for the client
package ops

import (
	"encoding/binary"
	"errors"
	"fmt"
	"math"

	"multes_client_library_priv/internal"
)

const (
	cLen               = internal.MaxPkgLen - 4
	fLen               = internal.MaxPkgLen - 2
	idxLen             = 2
	maxKLen            = 8 - idxLen
	perturbedGroupSize = 3
	rotationMatrixKey  = "rotmat"
)

type keyError struct {
	length int
}

func newKeyError(len int) *keyError {
	return &keyError{length: len}
}

func (e *keyError) Error() string {
	return fmt.Sprintf("The provided key can not be longer than %d Bytes", e.length)
}

var (
	errValTooLong = errors.New("Values of that length cannot be stored")
)

// Get performs a read operation at the store, obtaining the result value
// of the query key, or nil if it is not existing.
//
// An error is returned if the key argument is longer than supported, or
// a problem in the network communication ocurred.
func (c Client) Get(key []byte) ([]byte, error) {

	rh := internal.ValueResHandler{}

	if len(key) > maxKLen {
		return nil, newKeyError(maxKLen)
	}

	initKey := make([]byte, len(key)+idxLen)
	copy(initKey[idxLen:], key)

	gOp := internal.NewGetOp(initKey)

	err := c.conn.Send(gOp, &rh)

	if err != nil {
		return nil, err
	}

	pRes := gOp.Result

	if pRes == nil {
		return nil, nil
	}

	//--!--test--!--
	//numOps := (int(pRes[0])<<8 | int(pRes[1]))
	numOps := 0

	if numOps == 0 {
		//return pRes[2:], nil
		return pRes, nil
	}
	//--!--test--!--

	res := make([]byte, cLen+numOps*fLen)

	curLen := copy(res, pRes[2:])

	rqs := make([]*internal.Operation, numOps)

	for i := 0; i < numOps; i++ {

		reqKey := make([]byte, len(key)+idxLen)

		for j := idxLen - 1; j >= 0; j-- {
			reqKey[idxLen-j-1] = byte((i + 1) >> (8 * byte(j)))
		}

		copy(reqKey[idxLen:], key)

		rqs[i] = internal.NewGetOp(reqKey)
	}

	if err := c.conn.SendBulk(rqs, &rh); err != nil {
		return nil, err
	}

	for _, r := range rqs {

		if r.Result == nil {
			return nil, fmt.Errorf("Corrupted packet of key %x", r.Key)
		}

		curLen += copy(res[curLen:], r.Result)
	}

	return res[:curLen], nil
}

func (c Client) GetWithCheckpoint(key []byte, tokenBucketIdx int, tokensEachTick int, clkCyclesBeforeTick int, maxBurstSize int) ([]byte, error) {
	if len(key) > maxKLen {
		return nil, newKeyError(maxKLen)
	}

	initKey := make([]byte, len(key)+idxLen)
	copy(initKey[idxLen:], key)

	gOp := internal.NewGetWithCheckpoint(initKey, &internal.CheckpointConfig{TokenBucketIdx: byte(tokenBucketIdx),
		TokensEachTick: byte(tokensEachTick), ClkCyclesBeforeTick: byte(clkCyclesBeforeTick),
		MaxBurstSize: [2]byte{byte(maxBurstSize & 0xFF), byte((maxBurstSize >> 8) & 0xFF)}})

	rh := internal.ValueResHandler{}
	err := c.conn.Send(gOp, &rh)
	if err != nil {
		return nil, err
	}

	return gOp.Result, nil
}

func (c Client) GetPerturbed(key [][]byte, shouldDecompress bool) ([][]byte, error) {
	if len(key)%perturbedGroupSize != 0 {
		return nil, fmt.Errorf("Error GetPerturbed: the number of keys should be multiple of perturbedGroupSize.")
	}

	rqs := make([]*internal.Operation, len(key))
	for i := 0; i < len(key); i++ {
		if len(key[i]) > maxKLen {
			return nil, newKeyError(maxKLen)
		}

		initKey := make([]byte, len(key[i])+idxLen)
		copy(initKey[idxLen:], key[i])

		var value []byte
		if shouldDecompress {
			value = []byte{0x01, 0xFF}
		} else {
			value = []byte{0x00, 0xFF}
		}

		rqs[i] = internal.NewGetCondOp(initKey, value)
	}

	rh := internal.ValueResHandler{}
	err := c.conn.SendBulk(rqs, &rh)
	if err != nil {
		return nil, err
	}

	results := make([][]byte, len(key))
	for i, r := range rqs {
		if r.Result == nil {
			return nil, fmt.Errorf("Corrupted packet of key %x", r.Key)
		}
		results[i] = r.Result
	}

	return results, nil
}

func (c Client) GetBulkN(keys [][]byte, getCondNo int, getNo int, shouldDecompress bool, n int) ([][]byte, error) {
	if getCondNo%perturbedGroupSize != 0 {
		return nil, fmt.Errorf("Error GetBulkN: getCondNo should be multiple of perturbedGroupSize.")
	}
	if n%perturbedGroupSize != 0 {
		return nil, fmt.Errorf("Error GetBulkN: n should be multiple of perturbedGroupSize.")
	}

	results := make([][]byte, getCondNo+getNo)

	rqs := make([]*internal.Operation, n)
	rh := internal.ValueResHandler{}
	i := 0
	for ; i < getCondNo+getNo; i++ {
		initKey := make([]byte, len(keys[i])+idxLen)
		copy(initKey[idxLen:], keys[i])
		if shouldDecompress {
			if i < getCondNo {
				value := []byte{0x01, 0xFF}
				rqs[i%n] = internal.NewGetCondOp(initKey, value)
			} else {
				value := []byte{0x01, 0x00}
				rqs[i%n] = internal.NewGetCondOp(initKey, value)
			}
		} else {
			if i < getCondNo {
				value := []byte{0x00, 0xFF}
				rqs[i%n] = internal.NewGetCondOp(initKey, value)
			} else {
				rqs[i%n] = internal.NewGetOp(initKey)
			}
		}

		if (i+1)%n == 0 {
			err := c.conn.SendBulk(rqs, &rh)
			if err != nil {
				return nil, err
			}

			for j, r := range rqs {
				if r.Result == nil {
					return nil, fmt.Errorf("Corrupted packet of key %x", r.Key)
				}
				results[i-n+1+j] = r.Result
			}
		}
	}
	if i%n != 0 {
		err := c.conn.SendBulk(rqs[:(i%n)], &rh)
		if err != nil {
			return nil, err
		}

		for j := 0; j < i%n; j++ {
			if rqs[j].Result == nil {
				return nil, fmt.Errorf("Corrupted packet of key %x", rqs[j].Key)
			}
			results[i-i%n+j] = rqs[j].Result
		}
	}

	return results, nil
}

func (c Client) SetRotationMatrix(matrix [][]float64) error {
	matrixBytes := make([]byte, 8*len(matrix)*len(matrix[0]))
	for i := 0; i < len(matrix[0]); i++ {
		for j := 0; j < len(matrix); j++ {
			binary.LittleEndian.PutUint64(matrixBytes[(i*len(matrix)+j)*8:(i*len(matrix)+j)*8+8], math.Float64bits(matrix[j][i]))
		}
	}
	return c.Set([]byte(rotationMatrixKey), matrixBytes)
}

func (c Client) GetRotationMatrix() error {
	key := []byte(rotationMatrixKey)

	initKey := make([]byte, len(key)+idxLen)
	copy(initKey[idxLen:], key)

	value := []byte{0x00, 0xFE}

	op := internal.NewGetCondOp(initKey, value)

	rh := internal.ValueResHandler{}

	return c.conn.Send(op, &rh)
}

func (c Client) GetCond(key, value []byte) ([]byte, error) {
	if len(key) > maxKLen {
		return nil, newKeyError(maxKLen)
	}

	rh := internal.ValueResHandler{}

	initKey := make([]byte, len(key)+idxLen)
	copy(initKey[idxLen:], key)

	vLen := len(value)

	pLen := min(vLen, cLen)

	trimmedValue := make([]byte, pLen)
	copy(trimmedValue, value[:pLen])

	gOp := internal.NewGetCondOp(initKey, trimmedValue)

	err := c.conn.Send(gOp, &rh)
	if err != nil {
		return nil, err
	}

	pRes := gOp.Result
	if pRes == nil {
		return nil, nil
	}

	return pRes, nil
}

// Set performs a local write operation at the store, referencing
// the written value by the key argument and overwriting an existing
// value that was formerly referenced by that same key.
//
// An error is returned if the key argument is longer than supported, or
// a problem in the network communication ocurred.
func (c Client) Set(key, value []byte) error {
	return c.set(false, key, value)
}

// SetReplicated performs a replicated write operation at the store,
// referencing the written value by the key argument and overwriting
// an existing value that was formerly referenced by that same key.
//
// An error is returned if the key argument is longer than supported, or
// a problem in the network communication ocurred.
func (c Client) SetReplicated(key, value []byte) error {
	return c.set(true, key, value)
}

func min(a, b int) int {

	if a <= b {
		return a
	}

	return b
}

func (c Client) set(repl bool, key, value []byte) error {

	if len(key) > maxKLen {
		return newKeyError(maxKLen)
	}

	rh := internal.SimpleResHandler{}

	vLen := len(value)

	pLen := min(vLen, cLen)

	left := vLen - pLen

	numOps := int(math.Ceil(float64(left)/float64(fLen))) + 1

	if numOps > 1<<(idxLen*8) {
		return errValTooLong
	}

	rqs := make([]*internal.Operation, numOps)

	pKey := make([]byte, len(key)+idxLen)
	copy(pKey[idxLen:], key)

	//--!--test--!--
	// pVal := make([]byte, pLen+2)
	// pVal[0] = byte(((numOps - 1) >> 8))
	// pVal[1] = byte(numOps - 1)
	// copy(pVal[2:], value[:pLen])

	// fmt.Printf("numOps=%d\n\n", numOps)

	pVal := make([]byte, pLen)
	copy(pVal, value[:pLen])
	//--!--test--!--

	var pSet *internal.Operation

	if repl {
		pSet = internal.NewSetReplOp(pKey, pVal)
	} else {
		pSet = internal.NewSetOp(pKey, pVal)
	}

	rqs[0] = pSet

	var toSend int

	for i := 1; i < numOps; i++ {

		reqKey := make([]byte, len(key)+idxLen)

		for j := idxLen - 1; j >= 0; j-- {
			reqKey[idxLen-j-1] = byte(i >> (8 * byte(j)))
		}

		copy(reqKey[idxLen:], key)

		toSend = min(left, fLen)

		if repl {
			rqs[i] = internal.NewSetReplOp(reqKey, value[vLen-left:vLen-left+toSend])
		} else {
			rqs[i] = internal.NewSetOp(reqKey, value[vLen-left:vLen-left+toSend])
		}

		left -= toSend
	}

	return c.conn.SendBulk(rqs, &rh)
}

// Delete removes the value referenced by the given key at the store and
// returns a bool indicating the success of the operation, i.e. if the
// key held a value reference and it was deleted successfully.
//
// An error is returned if the key argument is longer than supported, or
// a problem in the network communication ocurred.
func (c Client) Delete(key []byte) (bool, error) {

	if len(key) > maxKLen {
		return false, newKeyError(maxKLen)
	}

	initKey := make([]byte, len(key)+idxLen)
	copy(initKey[idxLen:], key)

	gOp := internal.NewGetOp(initKey)

	err := c.conn.Send(gOp, &internal.ValueResHandler{})

	if err != nil {
		return false, err
	}

	if gOp.Result == nil {
		return false, nil
	}

	numOps := (int(gOp.Result[0])<<8 | int(gOp.Result[1])) + 1

	rqs := make([]*internal.Operation, numOps)

	rqs[0] = internal.NewDelOp(initKey)

	for i := 1; i < numOps; i++ {

		reqKey := make([]byte, len(key)+idxLen)

		for j := idxLen - 1; j >= 0; j-- {
			reqKey[idxLen-j-1] = byte(i >> (8 * byte(j)))
		}

		copy(reqKey[idxLen:], key)

		rqs[i] = internal.NewDelOp(reqKey)
	}

	rh := internal.EmptyResHandler{}

	if err := c.conn.SendBulk(rqs, &rh); err != nil {
		return false, err
	}

	return true, nil
}
