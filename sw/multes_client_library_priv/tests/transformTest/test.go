package main

import (
	"flag"
)

//

//

var matrix = []float64{0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3}

func main() {
	var (
		//err         error
		inFilePath  string
		hostAddress string
		memcached   bool
	)

	flag.BoolVar(&memcached, "m", false, "If set use memcached, default is false")
	flag.StringVar(&hostAddress, "h", "localhost:11211", "The address of the server (host:port)")
	flag.StringVar(&inFilePath, "f", "bank_labeled.parquet", "Path to the .parquet input file.")
	flag.Parse()

	// inFilePathWithoutExtension := inFilePath[:strings.IndexByte(inFilePath, '.')]
	// //csvFilePath := fmt.Sprintf("%s.csv", inFilePathWithoutExtension)
	// csvOut1FilePath := fmt.Sprintf("%s_t1.csv", inFilePathWithoutExtension)
	// //csvOut2FilePath := fmt.Sprintf("%s_t2.csv", inFilePathWithoutExtension)

	// var client *ops.Client
	// if memcached {
	// 	client = ops.NewTestClient(hostAddress)
	// } else {
	// 	client = ops.NewClient(hostAddress)
	// }

	// err = client.Connect()
	// if err != nil {
	// 	log.Fatalf("Error connect: %s\n", err)
	// }
	// defer client.Disconnect()

	// var schemaStruct parquet.ParquetSchema
	// var columns []string
	// if strings.Contains(inFilePath, "bank") {
	// 	schemaStruct = parquet.BankClientMarketingData{}
	// 	c := []string{"Age", "Job", "Marital", "Education", "Default", "Balance", "Housing", "Loan", "Contact", "Day", "Month", "Duration", "Campaign",
	// 		"Pdays", "Previous", "Poutcome", "Y"}
	// 	columns = c
	// } else if strings.Contains(inFilePath, "diabetes") {
	// 	schemaStruct = parquet.PimaIndiansDiabetesData{}
	// 	c := []string{"Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI", "DiabetesPedigreeFunction", "Age", "Outcome"}
	// 	columns = c
	// }

	// p, err := parquet.NewProcessor(client, schemaStruct)
	// if err != nil {
	// 	log.Fatalf("Error new processor: %s\n", err)
	// }

	// key := []byte("ttt")

	// err = p.StoreFile(key, inFilePath)
	// if err != nil {
	// 	log.Fatalf("Error store file: %s\n", err)
	// }

	// var matrixBytes []byte
	// for _, v := range matrix {
	// 	nrBuf := new(bytes.Buffer)
	// 	err := binary.Write(nrBuf, binary.LittleEndian, v)
	// 	if err != nil {
	// 		log.Fatal(err)
	// 	}
	// 	matrixBytes = append(matrixBytes, nrBuf.Bytes()...)
	// }
	// err = p.Client.Set([]byte("rotmat"), matrixBytes)
	// if err != nil {
	// 	log.Fatalf("Error set: %s\n", err)
	// }

	// err = p.Client.GetRotationMatrix([]byte("rotmat"))
	// if err != nil {
	// 	log.Fatalf("Error GetRotationMatrix: %s\n", err)
	// }

	// p.DisableColumn(p.ColumnsNo - 1)

	// data, err := p.GetPerturbedRows(key)
	// if err != nil {
	// 	log.Fatalf("Error GetPerturbedRows: %s\n", err)
	// }

	// stringData := make([][]string, len(data[0])+1)
	// for i := 0; i < len(data[0])+1; i++ {
	// 	stringData[i] = make([]string, len(data))
	// }

	// for i := 0; i < len(data); i++ {
	// 	stringData[0][i] = columns[i]
	// 	for j := 1; j <= len(data[0]); j++ {
	// 		stringData[j][i] = fmt.Sprintf("%f", data[i][j-1])
	// 	}
	// }

	// pfout, err := os.Create(csvOut1FilePath)
	// if err != nil {
	// 	panic(err)
	// }

	// csvWriter := csv.NewWriter(pfout)

	// err = csvWriter.WriteAll(stringData)
	// if err != nil {
	// 	panic(err)
	// }

	// csvWriter.Flush()

	// // err = p.GetFile(key, "./out.parquet")
	// // if err != nil {
	// // 	log.Fatalf("Error get file: %s\n", err)
	// // }
}
