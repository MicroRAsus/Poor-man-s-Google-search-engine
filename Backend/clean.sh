#!/bin/bash

if [ -d ./temp ]; then
        rm -r ./temp
fi
rm 2pass query DictFile.out MappingFile.out posting.out
cd ./src
rm 2pass.cpp query.cpp *.o
cd ./include
rm *.o
