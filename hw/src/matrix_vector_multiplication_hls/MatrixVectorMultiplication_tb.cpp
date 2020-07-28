#include "MatrixVectorMultiplication.h"

#define INPUTS_NO 4

int main() {
	IN ins[INPUTS_NO] = {
			{{0.1, 0.2, 0.3, 0.1, 0.2, 0.3, 0.1, 0.2, 0.3}, {0.0, -1.0, 0.0}},
			{{0.1, 0.2, 0.3, 0.1, 0.2, 0.3, 0.1, 0.2, 0.3}, {1.0, 339.0, 0.0}},
			{{0.1, 0.2, 0.3, 0.1, 0.2, 0.3, 0.1, 0.2, 0.3}, {0.0, -1.0, 0.0}},
			{{0.1, 0.2, 0.3, 0.1, 0.2, 0.3, 0.1, 0.2, 0.3}, {1.0, 339.0, 0.0}},
	};

	OUT outs[INPUTS_NO];

	for (int k = 0; k < INPUTS_NO; k++) {
		MatrixVectorMultiplication(ins[k], outs[k]);
	}

	for (int k = 0; k < INPUTS_NO; k++) {
		for (int i = 0; i < DIM; i++) {
			ENTRY_TYPE acc = 0;

			for (int j = 0; j < DIM; j++) {
				acc += ins[k].mat.vals[i][j] * ins[k].vec.vals[j];
			}

			if (acc != outs[k].res.vals[i]) {
				return 1;
			}
		}
	}

	return 0;
}
