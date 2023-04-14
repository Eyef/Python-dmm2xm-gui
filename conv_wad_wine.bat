@echo off
if not exist doom2d.wad goto nofiles
echo Converting...
dmm2xm -q 8  -f ALLRIGHT > convert.log
dmm2xm -q 6  -f BEST     >> convert.log
dmm2xm -q 8  -f GLAD     >> convert.log
dmm2xm -q 22 -f MENU     >> convert.log
dmm2xm -q 16 -f INTERMUS >> convert.log
dmm2xm -q 12 -f SUPER    >> convert.log
dmm2xm -q 8  -f АС       -o 01.xm >> convert.log
dmm2xm -q 12 -f АТАС     -o 02.xm >> convert.log
dmm2xm -q 8  -f АЙОЙ     -o 03.xm >> convert.log
dmm2xm -q 8  -f БОЖ_МУЗ  -o 04.xm >> convert.log
dmm2xm -q 12 -f БЫСТРОТА -o 05.xm >> convert.log
dmm2xm -q 8  -f С_ВЫШАК  -o 06.xm >> convert.log
dmm2xm -q 8  -f КЛАСС    -o 07.xm >> convert.log
dmm2xm -q 8  -f ДУШЕВНАЯ -o 08.xm >> convert.log
dmm2xm -q 16 -f ХЕХЕХЕ   -o 09.xm >> convert.log
dmm2xm -q 8  -f ХОХОХО   -o 10.xm >> convert.log
dmm2xm -q 10 -f КОНЕЦ    -o 11.xm >> convert.log
dmm2xm -q 8  -f МОЩЬ     -o 12.xm >> convert.log
dmm2xm -q 8  -f ПАЛАТА#6 -o 13.xm >> convert.log
dmm2xm -q 8  -f ПРИКОЛ   -o 14.xm >> convert.log
dmm2xm -q 8  -f ПРОБА    -o 15.xm >> convert.log
dmm2xm -q 8  -f ПРОСТОТА -o 16.xm >> convert.log
dmm2xm -q 8  -f СОЛО     -o 17.xm >> convert.log
dmm2xm -q 12 -f СПОК     -o 18.xm >> convert.log
dmm2xm -q 8  -f СТРАХ    -o 19.xm >> convert.log
dmm2xm -q 12 -f ТИШЬ     -o 20.xm >> convert.log
dmm2xm -q 8  -f ТЫ_ПОБЕД -o 21.xm >> convert.log
dmm2xm -q 16 -f ТЫ_ТРУП  -o 22.xm >> convert.log
dmm2xm -q 12 -f УЖАС     -o 23.xm >> convert.log
dmm2xm -q 12 -f ВЗБУЧКА  -o 24.xm >> convert.log
echo Finished.
goto:eof
:nofiles
echo Change current directory to doom2d.wad location.
