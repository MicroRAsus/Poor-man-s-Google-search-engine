#!/bin/bash

cd ./src/include
g++ -std=c++11 -c ./*.cpp
cd ../
flex -o 2pass.cpp ./2pass.lex
g++ -std=c++11 -c ./2pass.cpp -lfl
g++ ./include/*.o 2pass.o -o ../2pass -lfl
flex -o ./query.cpp ./query.lex
g++ -std=c++11 -c ./query.cpp -o ./query.o -lfl
g++ ./include/*.o ./query.o -o ../query -lfl
