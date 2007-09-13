@echo off
if not exist BEST.dmm goto nofiles
echo Converting...
chcp 1251 > nul
dmm2xm -q 8  ALLRIGHT.dmm > convert.log
dmm2xm -q 4  BEST.dmm     >> convert.log
dmm2xm -q 8  GLAD.dmm     >> convert.log
dmm2xm -q 8  MENU.dmm     >> convert.log
dmm2xm -q 16 INTERMUS.dmm >> convert.log
dmm2xm -q 12 SUPER.dmm    >> convert.log
dmm2xm -q 8  АС.dmm       >> convert.log
dmm2xm -q 6  АТАС.dmm     >> convert.log
dmm2xm -q 8  АЙОЙ.dmm     >> convert.log
dmm2xm -q 8  БОЖ_МУЗ.dmm  >> convert.log
dmm2xm -q 12 БЫСТРОТА.dmm >> convert.log
dmm2xm -q 8  С_ВЫШАК.dmm  >> convert.log
dmm2xm -q 4  КЛАСС.dmm    >> convert.log
dmm2xm -q 8  ДУШЕВНАЯ.dmm >> convert.log
dmm2xm -q 16 ХЕХЕХЕ.dmm   >> convert.log
dmm2xm -q 8  ХОХОХО.dmm   >> convert.log
dmm2xm -q 4  КОНЕЦ.dmm    >> convert.log
dmm2xm -q 4  МОЩЬ.dmm     >> convert.log
dmm2xm -q 8  ПАЛАТА#6.dmm >> convert.log
dmm2xm -q 4  ПРИКОЛ.dmm   >> convert.log
dmm2xm -q 8  ПРОБА.dmm    >> convert.log
dmm2xm -q 8  ПРОСТОТА.dmm >> convert.log
dmm2xm -q 8  СОЛО.dmm     >> convert.log
dmm2xm -q 12 СПОК.dmm     >> convert.log
dmm2xm -q 4  СТРАХ.dmm    >> convert.log
dmm2xm -q 12 ТИШЬ.dmm     >> convert.log
dmm2xm -q 10 ТЫ_ПОБЕД.dmm >> convert.log
dmm2xm -q 16 ТЫ_ТРУП.dmm  >> convert.log
dmm2xm -q 4  УЖАС.dmm     >> convert.log
dmm2xm -q 12 ВЗБУЧКА.dmm  >> convert.log
chcp 866 > nul
echo Finished.
goto:eof
:nofiles
echo Change current directory to DMM songs location.
