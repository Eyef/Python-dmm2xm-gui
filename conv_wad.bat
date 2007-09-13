@echo off
if not exist doom2d.wad goto nofiles
echo Converting...
chcp 1251 > nul
dmm2xm -q 8  -f ALLRIGHT doom2d.wad > convert.log
dmm2xm -q 4  -f BEST     doom2d.wad >> convert.log
dmm2xm -q 8  -f GLAD     doom2d.wad >> convert.log
dmm2xm -q 8  -f MENU     doom2d.wad >> convert.log
dmm2xm -q 16 -f INTERMUS doom2d.wad >> convert.log
dmm2xm -q 12 -f SUPER    doom2d.wad >> convert.log
dmm2xm -q 8  -f АС       doom2d.wad >> convert.log
dmm2xm -q 6  -f АТАС     doom2d.wad >> convert.log
dmm2xm -q 8  -f АЙОЙ     doom2d.wad >> convert.log
dmm2xm -q 8  -f БОЖ_МУЗ  doom2d.wad >> convert.log
dmm2xm -q 12 -f БЫСТРОТА doom2d.wad >> convert.log
dmm2xm -q 8  -f С_ВЫШАК  doom2d.wad >> convert.log
dmm2xm -q 4  -f КЛАСС    doom2d.wad >> convert.log
dmm2xm -q 8  -f ДУШЕВНАЯ doom2d.wad >> convert.log
dmm2xm -q 16 -f ХЕХЕХЕ   doom2d.wad >> convert.log
dmm2xm -q 8  -f ХОХОХО   doom2d.wad >> convert.log
dmm2xm -q 4  -f КОНЕЦ    doom2d.wad >> convert.log
dmm2xm -q 4  -f МОЩЬ     doom2d.wad >> convert.log
dmm2xm -q 8  -f ПАЛАТА#6 doom2d.wad >> convert.log
dmm2xm -q 4  -f ПРИКОЛ   doom2d.wad >> convert.log
dmm2xm -q 8  -f ПРОБА    doom2d.wad >> convert.log
dmm2xm -q 8  -f ПРОСТОТА doom2d.wad >> convert.log
dmm2xm -q 8  -f СОЛО     doom2d.wad >> convert.log
dmm2xm -q 12 -f СПОК     doom2d.wad >> convert.log
dmm2xm -q 4  -f СТРАХ    doom2d.wad >> convert.log
dmm2xm -q 12 -f ТИШЬ     doom2d.wad >> convert.log
dmm2xm -q 10 -f ТЫ_ПОБЕД doom2d.wad >> convert.log
dmm2xm -q 16 -f ТЫ_ТРУП  doom2d.wad >> convert.log
dmm2xm -q 4  -f УЖАС     doom2d.wad >> convert.log
dmm2xm -q 12 -f ВЗБУЧКА  doom2d.wad >> convert.log
chcp 866 > nul
echo Finished.
goto:eof
:nofiles
echo Change current directory to doom2d.wad location.
