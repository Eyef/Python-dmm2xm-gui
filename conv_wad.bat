@echo off
if not exist doom2d.wad goto nofiles
echo Converting...
chcp 1251 > nul
dmm2xm -q 8  -f ALLRIGHT > convert.log
dmm2xm -q 6  -f BEST     >> convert.log
dmm2xm -q 8  -f GLAD     >> convert.log
dmm2xm -q 22 -f MENU     >> convert.log
dmm2xm -q 16 -f INTERMUS >> convert.log
dmm2xm -q 12 -f SUPER    >> convert.log
dmm2xm -q 8  -f АС       >> convert.log
dmm2xm -q 12 -f АТАС     >> convert.log
dmm2xm -q 8  -f АЙОЙ     >> convert.log
dmm2xm -q 8  -f БОЖ_МУЗ  >> convert.log
dmm2xm -q 12 -f БЫСТРОТА >> convert.log
dmm2xm -q 8  -f С_ВЫШАК  >> convert.log
dmm2xm -q 8  -f КЛАСС    >> convert.log
dmm2xm -q 8  -f ДУШЕВНАЯ >> convert.log
dmm2xm -q 16 -f ХЕХЕХЕ   >> convert.log
dmm2xm -q 8  -f ХОХОХО   >> convert.log
dmm2xm -q 10 -f КОНЕЦ    >> convert.log
dmm2xm -q 8  -f МОЩЬ     >> convert.log
dmm2xm -q 8  -f ПАЛАТА#6 >> convert.log
dmm2xm -q 8  -f ПРИКОЛ   >> convert.log
dmm2xm -q 8  -f ПРОБА    >> convert.log
dmm2xm -q 8  -f ПРОСТОТА >> convert.log
dmm2xm -q 8  -f СОЛО     >> convert.log
dmm2xm -q 12 -f СПОК     >> convert.log
dmm2xm -q 8  -f СТРАХ    >> convert.log
dmm2xm -q 12 -f ТИШЬ     >> convert.log
dmm2xm -q 8  -f ТЫ_ПОБЕД >> convert.log
dmm2xm -q 16 -f ТЫ_ТРУП  >> convert.log
dmm2xm -q 12 -f УЖАС     >> convert.log
dmm2xm -q 12 -f ВЗБУЧКА  >> convert.log
chcp 866 > nul
echo Finished.
goto:eof
:nofiles
echo Change current directory to doom2d.wad location.
