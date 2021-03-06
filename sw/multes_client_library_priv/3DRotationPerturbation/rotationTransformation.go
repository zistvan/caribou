package main

import (
	"fmt"
	"math"
	"math/rand"
	"time"
)

const minNormalization = 0
const maxNormalization = 5

func normalize(data [][]float64) [][]float64 {
	normalizedData := make([][]float64, len(data))
	for i := range normalizedData {
		normalizedData[i] = make([]float64, len(data[0]))
	}

	minData := make([]float64, len(data[0]))
	copy(minData, data[0])
	maxData := make([]float64, len(data[0]))
	copy(maxData, data[0])

	for _, dataRecord := range data {
		for i, v := range dataRecord {
			if v < minData[i] {
				minData[i] = v
			}
			if v > maxData[i] {
				maxData[i] = v
			}
		}
	}

	for i, dataRecord := range data {
		for j, elem := range dataRecord {
			normalizedData[i][j] = minNormalization + (elem-minData[j])*(maxNormalization-minNormalization)/
				(maxData[j]-minData[j])
		}
	}

	return normalizedData
}

func rotationMatrixXY(angle float64) [][]float64 {
	sinA := math.Sin(angle)
	cosA := math.Cos(angle)
	sinASq := sinA * sinA
	cosASq := cosA * cosA
	sinAcosA := sinA * cosA

	return [][]float64{
		{cosA, 0, sinA},
		{sinASq, cosA, -sinAcosA},
		{-sinAcosA, sinA, cosASq}}
}

func rotationMatrixYZ(angle float64) [][]float64 {
	sinA := math.Sin(angle)
	cosA := math.Cos(angle)
	sinASq := sinA * sinA
	cosASq := cosA * cosA
	sinAcosA := sinA * cosA

	return [][]float64{
		{cosASq, -sinAcosA, sinA},
		{sinA, cosA, 0},
		{-sinAcosA, sinASq, cosA}}
}

func rotationMatrixXZ(angle float64) [][]float64 {
	sinA := math.Sin(angle)
	cosA := math.Cos(angle)
	sinASq := sinA * sinA
	cosASq := cosA * cosA
	sinAcosA := sinA * cosA

	return [][]float64{
		{cosA, -sinA, 0},
		{sinAcosA, cosASq, -sinA},
		{sinASq, sinAcosA, cosA}}
}

func rotateVector3D(rotationMatrix [][]float64, vec []float64) []float64 {
	result := make([]float64, len(vec))

	for i := range result {
		for j := range result {
			result[i] += rotationMatrix[i][j] * vec[j]
		}
	}

	return result
}

func rotateData3D(data [][]float64, rotationMatrix [][]float64, columnPermutation []int) [][]float64 {
	rotatedData := make([][]float64, len(data))
	for i := range rotatedData {
		rotatedData[i] = make([]float64, len(data[0]))
	}

	for i, dataRecord := range data {
		for j := 0; j < len(columnPermutation); j += 3 {
			rotated := rotateVector3D(rotationMatrix, []float64{dataRecord[columnPermutation[j]],
				dataRecord[columnPermutation[j+1]], dataRecord[columnPermutation[j+2]]})

			for k := 0; k < 3; k++ {
				if j+k < len(dataRecord) {
					rotatedData[i][columnPermutation[j+k]] = rotated[k]
				}
			}
		}
	}

	return rotatedData
}

func getBestRotationMatrix(data [][]float64, columnPermutation []int) [][]float64 {
	sumDiffXY := make([][360]float64, len(data[0]))
	sumDiffYZ := make([][360]float64, len(data[0]))
	sumDiffXZ := make([][360]float64, len(data[0]))

	maxSumDiffXY := make([]float64, len(data[0]))
	maxSumDiffYZ := make([]float64, len(data[0]))
	maxSumDiffXZ := make([]float64, len(data[0]))

	for angle := 0; angle < 360; angle++ {
		rotationMatrixXY := rotationMatrixXY(float64(angle) * math.Pi / 180.0)
		rotationMatrixYZ := rotationMatrixYZ(float64(angle) * math.Pi / 180.0)
		rotationMatrixXZ := rotationMatrixXZ(float64(angle) * math.Pi / 180.0)

		for _, dataRow := range data {
			for i := 0; i < len(columnPermutation); i += 3 {
				rotatedXY := rotateVector3D(rotationMatrixXY, []float64{dataRow[columnPermutation[i]],
					dataRow[columnPermutation[i+1]], dataRow[columnPermutation[i+2]]})
				rotatedYZ := rotateVector3D(rotationMatrixYZ, []float64{dataRow[columnPermutation[i]],
					dataRow[columnPermutation[i+1]], dataRow[columnPermutation[i+2]]})
				rotatedXZ := rotateVector3D(rotationMatrixXZ, []float64{dataRow[columnPermutation[i]],
					dataRow[columnPermutation[i+1]], dataRow[columnPermutation[i+2]]})

				for j := 0; j < 3; j++ {
					if i+j < len(data[0]) {
						sumDiffXY[columnPermutation[i+j]][angle] += math.Abs(dataRow[columnPermutation[i+j]] - rotatedXY[j])
						sumDiffYZ[columnPermutation[i+j]][angle] += math.Abs(dataRow[columnPermutation[i+j]] - rotatedYZ[j])
						sumDiffXZ[columnPermutation[i+j]][angle] += math.Abs(dataRow[columnPermutation[i+j]] - rotatedXZ[j])
					}
				}
			}
		}

		for i := range data[0] {
			if sumDiffXY[i][angle] > maxSumDiffXY[i] {
				maxSumDiffXY[i] = sumDiffXY[i][angle]
			}
			if sumDiffYZ[i][angle] > maxSumDiffYZ[i] {
				maxSumDiffYZ[i] = sumDiffYZ[i][angle]
			}
			if sumDiffXZ[i][angle] > maxSumDiffXZ[i] {
				maxSumDiffXZ[i] = sumDiffXZ[i][angle]
			}
		}
	}

	bestAngleXY := 0
	maxPrivacyXY := 0.0
	bestAngleYZ := 0
	maxPrivacyYZ := 0.0
	bestAngleXZ := 0
	maxPrivacyXZ := 0.0

	for angle := 0; angle < 360; angle++ {
		privacyXY := 0.0
		privacyYZ := 0.0
		privacyXZ := 0.0
		for i := range data[0] {
			privacyXY += sumDiffXY[i][angle] / maxSumDiffXY[i]
			privacyYZ += sumDiffYZ[i][angle] / maxSumDiffYZ[i]
			privacyXZ += sumDiffXZ[i][angle] / maxSumDiffXZ[i]
		}
		if privacyXY > maxPrivacyXY {
			maxPrivacyXY = privacyXY
			bestAngleXY = angle
		}
		if privacyYZ > maxPrivacyYZ {
			maxPrivacyYZ = privacyYZ
			bestAngleYZ = angle
		}
		if privacyXZ > maxPrivacyXZ {
			maxPrivacyXZ = privacyXZ
			bestAngleXZ = angle
		}
	}

	if maxPrivacyXY >= maxPrivacyYZ && maxPrivacyXY >= maxPrivacyXZ {
		fmt.Printf("XY %d\n", bestAngleXY)
		return rotationMatrixXY(float64(bestAngleXY) * math.Pi / 180.0)
	} else if maxPrivacyYZ >= maxPrivacyXY && maxPrivacyYZ >= maxPrivacyXZ {
		fmt.Printf("YZ %d\n", bestAngleYZ)
		return rotationMatrixYZ(float64(bestAngleYZ) * math.Pi / 180.0)
	} else {
		fmt.Printf("XZ %d\n", bestAngleXZ)
		return rotationMatrixXZ(float64(bestAngleXZ) * math.Pi / 180.0)
	}
}

func rotationTransformation(data [][]float64) [][]float64 {
	normalizedData := normalize(data)

	columnPermutation := randomPermutation(len(data[0]))

	fmt.Printf("%v\n", columnPermutation)

	rotationMatrix := getBestRotationMatrix(normalizedData, columnPermutation)

	transformedData := rotateData3D(data, rotationMatrix, columnPermutation)

	return transformedData
}

func randomPermutation(size int) []int {
	permutation := make([]int, size)
	for i := range permutation {
		permutation[i] = i
	}

	randomSource := rand.NewSource(time.Now().UnixNano())
	random := rand.New(randomSource)
	for i := size; i > 1; i-- {
		pick := random.Intn(i)
		permutation[pick], permutation[i-1] = permutation[i-1], permutation[pick]
	}

	if size%3 == 0 {
		return permutation
	} else {
		i := 3 - size%3
		for i > 0 {
			pick := random.Intn(size)
			permutation = append(permutation, pick)
			i--
		}
		return permutation
	}
}
