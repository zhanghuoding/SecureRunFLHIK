#!/bin/sh

cd ./lib_src/
echo "CC = gcc" > makefile 
echo " " >> makefile 
echo "all:liballoc.o libstring.o" >> makefile
echo " " >> makefile 
echo "liballoc.o:liballoc.c" >> makefile
echo "	\$(CC) -c liballoc.c" >> makefile
echo "libstring.o:libstring.c" >> makefile
echo "	\$(CC) -c libstring.c" >> makefile
echo " " >> makefile 
echo "clean:" >> makefile
echo "	rm *.o" >> makefile
make
cd ../
make

