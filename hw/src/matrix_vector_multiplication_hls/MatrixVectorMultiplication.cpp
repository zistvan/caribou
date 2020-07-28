#include "MatrixVectorMultiplication.h"

void MatrixVectorMultiplication(IN in, OUT& out) {
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATA_PACK variable=in
#pragma HLS INTERFACE axis register both port=in
#pragma HLS DATA_PACK variable=out
#pragma HLS INTERFACE axis register both port=out

	for (int i = 0; i < DIM; i++) {
		ENTRY_TYPE acc = 0;

		for (int j = 0; j < DIM; j++) {
		#pragma HLS UNROLL
			acc += in.mat.vals[i][j] * in.vec.vals[j];
		}

		out.res.vals[i] = acc;
	}
}
