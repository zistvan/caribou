package ops

import (
	"errors"
	"sync"
)

var (
	ArrIdxLen      = 3
	maxArrKeyLen   = maxKLen - ArrIdxLen
	errOutOfBounds = errors.New("Array index out of bounds")
	errArrSize     = errors.New("Array is to big to be indexable")
)

func buildKey(arrKey []byte, idx int) []byte {

	key := make([]byte, len(arrKey)+ArrIdxLen)

	for j := ArrIdxLen - 1; j >= 0; j-- {
		key[ArrIdxLen-j-1] = byte(idx >> (8 * byte(j)))
	}

	copy(key[ArrIdxLen:], arrKey)

	return key
}

func (c Client) GetArrayDir(key []byte) ([]byte, error) {

	if len(key) > maxArrKeyLen {
		return nil, newKeyError(maxArrKeyLen)
	}

	pKey := make([]byte, len(key)+ArrIdxLen)
	copy(pKey[ArrIdxLen:], key)

	dirVal, err := c.Get(pKey)

	if err != nil {
		return nil, err
	}

	if dirVal == nil {
		return nil, nil
	}

	if len(dirVal)/ArrIdxLen > (1 << (8 * uint(ArrIdxLen))) {
		return nil, errArrSize
	}

	return dirVal, nil
}

type jobSet struct {
	index int
	value []byte
}

func (c Client) arraySetWorker(id int, wg *sync.WaitGroup, jobs <-chan jobSet, errors chan<- error, key []byte) {

	w := c.clone()
	err := w.Connect()
	if err != nil {
		errors <- err
	}

	defer w.Disconnect()

	for j := range jobs {

		if err = w.Set(buildKey(key, j.index), j.value); err != nil {
			errors <- err
		}

		wg.Done()
	}
}

func (c Client) ArraySetN(key []byte, vls [][]byte, np int) error {

	if len(key) > maxArrKeyLen {
		return newKeyError(maxArrKeyLen)
	}

	if vls == nil {
		return errors.New("Array values to be set are empty")
	}

	if len(vls) > (1 << (8 * uint(ArrIdxLen))) {
		return errArrSize
	}

	jobs := make(chan jobSet, len(vls)+1)
	errors := make(chan error, len(vls)+1)

	dirVal := make([]byte, len(vls)*ArrIdxLen)

	for i := 0; i < len(vls); i++ {

		for j := ArrIdxLen - 1; j >= 0; j-- {
			dirVal[i*ArrIdxLen+ArrIdxLen-j-1] = byte((i + 1) >> (8 * byte(j)))
		}
	}

	var wg sync.WaitGroup

	for i := 0; i < np; i++ {
		go c.arraySetWorker(i, &wg, jobs, errors, key)
	}

	for i := 1; i <= len(vls); i++ {
		jobs <- jobSet{index: i, value: vls[i-1]}
		wg.Add(1)
	}

	jobs <- jobSet{index: 0, value: dirVal}
	wg.Add(1)

	close(jobs)

	wg.Wait()

	select {
	case err := <-errors:
		return err
	default:
	}

	return nil
}

// ArraySet sets a new array, referenced by the given key argument.
//
// The key has to have a maximum length of 5 Byte.
//
// Returns an error if one of the partial set operations fails or
// the key is too long.
func (c Client) ArraySet(key []byte, vls [][]byte) error {

	if len(key) > maxArrKeyLen {
		return newKeyError(maxArrKeyLen)
	}

	if vls == nil {
		return errors.New("Array values to be set are empty")
	}

	if len(vls) > (1 << (8 * uint(ArrIdxLen))) {
		return errArrSize
	}

	dirVal := make([]byte, len(vls)*ArrIdxLen)

	reqK := make([][]byte, len(vls)+1)
	reqV := make([][]byte, len(vls)+1)

	copy(reqV, vls)

	for i := 0; i < len(vls); i++ {

		for j := ArrIdxLen - 1; j >= 0; j-- {
			dirVal[i*ArrIdxLen+ArrIdxLen-j-1] = byte((i + 1) >> (8 * byte(j)))
		}

		reqK[i] = buildKey(key, i+1)
	}

	pKey := make([]byte, len(key)+ArrIdxLen)
	copy(pKey[ArrIdxLen:], key)

	reqV[len(vls)] = dirVal
	reqK[len(vls)] = pKey

	return c.BatchSet(reqK, reqV)
}

// ArrayGet gets all elements of the array identified by the given key.
//
// The key has to have a maximum length of 5 Byte.
//
// Returns an error if one of the partial get operations fails or
// the key is too long.
func (c Client) ArrayGet(key []byte) ([][]byte, error) {

	dirVal, err := c.GetArrayDir(key)

	if err != nil {
		return nil, err
	}

	if dirVal == nil {
		return nil, nil
	}

	res := make([][]byte, len(dirVal)/ArrIdxLen)

	for i := 0; i < len(dirVal)/ArrIdxLen; i++ {

		curKey := make([]byte, len(key)+ArrIdxLen)

		copy(curKey[:ArrIdxLen], dirVal[i*ArrIdxLen:(i+1)*ArrIdxLen])
		copy(curKey[ArrIdxLen:], key)

		res[i], err = c.Get(curKey)

		if err != nil {
			return nil, err
		}
	}

	return res, nil
}

// ArraySetElem sets the element at position idx of the array identified
// by the given key argument.
//
// The key has to have a maximum length of 5 Byte.
//
// Returns an error if the value could not be set, the index is outside
// of the array bounds, or the key is too long.
func (c Client) ArraySetElem(key []byte, idx int, value []byte) error {

	if len(key) > maxArrKeyLen {
		return newKeyError(maxArrKeyLen)
	}

	pKey := make([]byte, len(key)+ArrIdxLen)
	copy(pKey[ArrIdxLen:], key)

	dirVal, err := c.Get(pKey)

	if err != nil {
		return err
	}

	if dirVal == nil {
		return nil
	}

	if idx < 0 || idx >= len(dirVal)/ArrIdxLen {
		return errOutOfBounds
	}

	if _, err := c.Delete(buildKey(key, idx+1)); err != nil {
		return err
	}

	if err := c.Set(buildKey(key, idx+1), value); err != nil {
		return err
	}

	return nil
}

// ArrayGetElem gets the element at position idx of the array identified
// by the given key argument.
//.
// The key has to have a maximum length of 5 Byte.
//
// Returns an error if the value could not be received, the index is
// outside of the array bounds or the key is too long.
func (c Client) ArrayGetElem(key []byte, idx int) ([]byte, error) {

	dirVal, err := c.GetArrayDir(key)

	if err != nil {
		return nil, err
	}

	if idx < 0 || idx >= len(dirVal)/ArrIdxLen {
		return nil, errOutOfBounds
	}

	qKey := make([]byte, len(key)+ArrIdxLen)

	copy(qKey[:ArrIdxLen], dirVal[idx*ArrIdxLen:(idx+1)*ArrIdxLen])
	copy(qKey[ArrIdxLen:], key)

	return c.Get(qKey)
}

func (c Client) ArrayGetElemKey(dirVal []byte, key []byte, idx int) ([]byte, error) {
	if len(dirVal) == 0 {
		return nil, errors.New("Empty array directory.")
	}

	if idx < 0 || idx >= len(dirVal)/ArrIdxLen {
		return nil, errOutOfBounds
	}

	qKey := make([]byte, len(key)+ArrIdxLen)

	copy(qKey[:ArrIdxLen], dirVal[idx*ArrIdxLen:(idx+1)*ArrIdxLen])
	copy(qKey[ArrIdxLen:], key)

	return qKey, nil
}

// ArrayDelete deletes an array identified by the key argument and
// returns a bool indicating the success of the operation.
//
// The key has to have a maximum length of 5 Byte.
//
// This is the recommended way of deleting an array and it
// has to be performed before the array key is to be overwritten
// by any Set operation.
//
// Returns an error if one of the partial delete operation
// fails or the key is too long. In case an error occurres,
// the consistency of the array is <b>not</b> guaranteed.
func (c Client) ArrayDelete(key []byte) (bool, error) {

	dirVal, err := c.GetArrayDir(key)

	if err != nil {
		return false, err
	}

	suc := true

	for i := 0; i < len(dirVal)/ArrIdxLen; i++ {

		curKey := make([]byte, len(key)+ArrIdxLen)

		copy(curKey[:ArrIdxLen], dirVal[i*ArrIdxLen:(i+1)*ArrIdxLen])
		copy(curKey[ArrIdxLen:], key)

		b, err := c.Delete(curKey)

		suc = suc && b

		if err != nil {
			return b, err
		}
	}

	if suc {

		b, err := c.Delete(buildKey(key, 0))

		suc = suc && b

		if err != nil {
			return suc, err
		}

	}

	return suc, nil
}
