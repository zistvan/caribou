result="varSize.txt"
rm $result

ipA=$1
port=$2

echo "Prep,Read,Proc,ResSize" >> $result

for size in 10 20 30 40 50 60 70 80
do
    	echo "Benchmark for $size k rows..."
        ./store/store -s $size -h $1:$2 $3
        ./bench -s $size -h $1:$2 $3 >> $result
done
echo "Done"
