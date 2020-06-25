package ops

import (
	//"encoding/binary"
	"math"
	//"os"

	"multes_client_library_priv/internal"
	//"gitlab.software.imdea.org/fpga/multes/sw/client-library/ops/parquet"
	//"gitlab.software.imdea.org/fpga/multes/sw/client-library/ops/parquet/transformable"
)

// BatchSet performs several high-level sets in a single batch on network level
// Might be useful for higher-level operations to efficiently set a bulk of values
func (c Client) BatchSet(keys, values [][]byte) error {

	rqs := make([]*internal.Operation, 0, len(keys))

	rh := internal.SimpleResHandler{}

	for i, key := range keys {

		value := values[i]

		if len(key) > maxKLen {
			return newKeyError(maxKLen)
		}

		vLen := len(value)

		pLen := min(vLen, cLen)

		left := vLen - pLen

		numOps := int(math.Ceil(float64(left)/float64(fLen))) + 1

		if numOps > 1<<(idxLen*8) {
			return errValTooLong
		}

		pKey := make([]byte, len(key)+idxLen)
		copy(pKey[idxLen:], key)

		pVal := make([]byte, pLen+2)
		pVal[0] = byte(((numOps - 1) >> 8))
		pVal[1] = byte(numOps - 1)
		copy(pVal[2:], value[:pLen])

		pSet := internal.NewSetOp(pKey, pVal)

		rqs = append(rqs, pSet)

		var toSend int

		for i := 1; i < numOps; i++ {

			reqKey := make([]byte, len(key)+idxLen)

			for j := idxLen - 1; j >= 0; j-- {
				reqKey[idxLen-j-1] = byte(i >> (8 * byte(j)))
			}

			copy(reqKey[idxLen:], key)

			toSend = min(left, fLen)

			rqs = append(rqs, internal.NewSetOp(reqKey, value[vLen-left:vLen-left+toSend]))

			left -= toSend
		}
	}

	return c.conn.SendBulk(rqs, &rh)
}

// // HParquetSet is a hack, where parquet files are set like plain keys, only identified by
// // a single key byte. The goal is to reach the maximum savable size of a parquet file on the
// // FPGA. Returns an error if a problem occurs on the network level and an integer indicating
// // the amount of chunks of the saved parquet file.
// //
// // Makes use of experimental function superset, which bundles multiple high-level sets and
// // performs them in a bulk
// //
// // Deprecated: Currently doesn't lead to better performance than common methods
// func (c Client) hParquetSet(key byte, file string, s transformable.Schema) (int, error) {

// 	t, _ := transformable.GetType(s)

// 	divider, err := parquet.NewParquetDivider("out", file, t, 508)

// 	if err != nil {
// 		return 0, err
// 	}

// 	chunks, err := divider.DivideFile()

// 	keys := make([][]byte, len(chunks))

// 	for i, ch := range chunks {

// 		keyBuf := make([]byte, 6)

// 		keyBuf[0] = key
// 		binary.PutUvarint(keyBuf[1:], uint64(i))

// 		keys[i] = keyBuf

// 		if err := c.Set(keyBuf, ch); err != nil {
// 			return i, err
// 		}
// 	}

// 	return len(chunks), err
// 	//return len(chunks), c.fastSet(keys, chunks)
// }

// // Deprecated: Currently doesn't lead to better performance than common methods
// func (c Client) hParquetGet(key byte, file string, s transformable.Schema, numChunks int) error {

// 	chunks := make([][]byte, numChunks)

// 	var err error

// 	for i := 0; i < numChunks; i++ {
// 		keyBuf := make([]byte, 6)

// 		keyBuf[0] = key
// 		binary.PutUvarint(keyBuf[1:], uint64(i))

// 		chunks[i], err = c.Get(keyBuf)

// 		if err != nil {
// 			return err
// 		}
// 	}

// 	t, _ := transformable.GetType(s)

// 	f, err := os.Open(file)

// 	if err != nil {
// 		return err
// 	}

// 	composer, err := parquet.NewParquetComposer(chunks, f, t)

// 	if err != nil {
// 		return err
// 	}
// 	err = composer.ComposeFile()

// 	composer.Close()

// 	return err
// }
