#!/bin/bash

if [ ! -d ./temp ]; then
	mkdir ./temp
else
	rm -r ./temp
	mkdir ./temp
fi
./2pass "$1" "$2"
rm -r ./temp
