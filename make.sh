#!/bin/sh
#
#vc -v +tos -lgem -lvc -lm polygon.asm -o POLYGON.PRG

#echo "Compiling..."
#vbccm68k -quiet "floatstr.c" -o= "floatstr.asm" -I$PWD/include  -O=1 -I$VBCC/targets/m68k-atari/include
echo "Assembling..."
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "GLOBALS.s" -o "globals.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "polygon.asm" -o "polygon.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "MAINWND.s" -o "mainwnd.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "include/AESLIB.S" -o "aeslib.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "include/VDILIB.S" -o "vdilib.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "include/KSPACKET.I" -o "kspacket.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "SURFCMAP.s" -o "surfcmap.o"

echo "Linking..."
vlink -EB -bataritos -x -Cvbcc -nostdlib $VBCC/targets/m68k-atari/lib/startup.o "aeslib.o" "vdilib.o" "globals.o" "kspacket.o" "polygon.o" "surfcmap.o" "mainwnd.o" -lm -L$VBCC/targets/m68k-atari/lib -lvc -o POLYGON.PRG
