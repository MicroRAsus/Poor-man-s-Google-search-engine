#!/bin/bash

flex tokenize.lex
g++ -o tokenize lex.yy.c -lfl
./tokenize /home/sgauch/public_html/5533/files/
cat ./output/* | sort | uniq -c | sort -nr > result.out
echo "Finished"
