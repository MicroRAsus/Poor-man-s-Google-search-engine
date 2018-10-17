#!/bin/bash

rm pass1 pass2 FinalDictFile.out  MappingFile.out tempDictFile.out posting.out
cd ./src/include
rm *.o
g++ -c ./*.cpp
cd ../
rm pass1.cpp *.o
flex -o pass1.cpp ./pass1.lex
g++ -std=c++11 -c ./pass1.cpp -lfl
g++ ./include/*.o pass1.o -o ../pass1 -lfl
g++ -c ./pass2.cpp -o ./pass2.o
g++ ./include/*.o pass2.o -o ../pass2
cd ../
if [ ! -d ./temp ]; then
	mkdir ./temp
else
	rm -r ./temp
	mkdir ./temp
fi
./pass1 "$1" "$2"
./pass2
