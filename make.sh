#!/bin/sh
#
#vc -v +tos -lgem -lvc -lm polygon.asm -o POLYGON.PRG

#echo "Compiling..."
#vbccm68k -quiet "floatstr.c" -o= "floatstr.asm" -I$PWD/include  -O=1 -I$VBCC/targets/m68k-atari/include
echo "Assembling..."
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "polygon.asm" -o "polygon.o"
echo "Linking..."
vlink -EB -bataritos -x -Bstatic -Cvbcc -nostdlib $VBCC/targets/m68k-atari/lib/startup.o "polygon.o" -lm -L$VBCC/targets/m68k-atari/lib -lvc -o POLYGON.PRG
