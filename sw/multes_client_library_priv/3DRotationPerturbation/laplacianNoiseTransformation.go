// package main

// import (
// 	"math"
// 	"math/rand"
// )

// const noiseScale = 10.0

// func getLaplacianNoise(scale float64) float64 {
// 	sign := rand.Float64()
// 	value := scale * math.Log(rand.Float64())
// 	if sign < 0.5 {
// 		return -value
// 	}
// 	return value
// }

// func laplacianNoiseTransformation(data [][]float64) [][]float64 {
// 	noisyData := make([][]float64, len(data))
// 	for i := range noisyData {
// 		noisyData[i] = make([]float64, len(data[0]))
// 	}

// 	for i, dataRecord := range data {
// 		for j, v := range dataRecord {
// 			noisyData[i][j] = v + getLaplacianNoise(noiseScale)
// 		}
// 	}

// 	return noisyData
// }
