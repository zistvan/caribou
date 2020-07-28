#ifndef MATRIX_VECTOR_MULTIPLICATION_H
#define MATRIX_VECTOR_MULTIPLICATION_H

const unsigned DIM = 3;

typedef double ENTRY_TYPE;

typedef struct _MATRIX {
	ENTRY_TYPE vals[DIM][DIM];
} MATRIX;

typedef struct _VECTOR {
	ENTRY_TYPE vals[DIM];
} VECTOR;

typedef struct _IN {
	MATRIX mat;
	VECTOR vec;
} IN;

typedef struct _OUT {
	VECTOR res;
} OUT;

void MatrixVectorMultiplication(IN in, OUT& out);

#endif
