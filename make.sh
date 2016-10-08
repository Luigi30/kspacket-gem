#!/bin/sh
#
#vc -v +tos -lgem -lvc -lm polygon.asm -o POLYGON.PRG

#echo "Compiling..."
#vbccm68k -quiet "floatstr.c" -o= "floatstr.asm" -I$PWD/include  -O=1 -I$VBCC/targets/m68k-atari/include
echo "Assembling..."
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/GLOBALS.s" -o "./obj/globals.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/polygon.asm" -o "./obj/polygon.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/MAINWND.s" -o "./obj/mainwnd.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/include/AESLIB.S" -o "./obj/aeslib.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/include/VDILIB.S" -o "./obj/vdilib.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/KSPACKET.S" -o "./obj/kspacket.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/SURFCMAP.s" -o "./obj/surfcmap.o"
vasmm68k_mot -quiet -Faout -mid=2 -phxass -nowarn=62 "./src/strings.s" -o "./obj/strings.o"

cp ./resource/*.RSH ./src/

echo "Linking..."
vlink -EB -bataritos -x -nostdlib -Cvbcc $VBCC/targets/m68k-atari/lib/startup.o "./obj/aeslib.o" "./obj/vdilib.o" "./obj/globals.o" "./obj/strings.o" "./obj/kspacket.o" "./obj/polygon.o" "./obj/surfcmap.o" "./obj/mainwnd.o" -lm -L$VBCC/targets/m68k-atari/lib -lvc -o KSP.PRG
