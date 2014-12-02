@echo off
echo.
echo Estes arquivos de compilacao foram criados apenas pra teste
echo.
echo fazem parte do Harbour hbcurl.ch, hbcompat.ch, hbxml.ch
echo apague desta pasta e use os arquivos do seu proprio Harbour
echo.
echo o arquivo hbnfe.ch e o mesmo da pasta ..\include copiado so pra facilitar compilacao
echo.
echo no hbp esta usando workdir=d:\temp, ajuste para sua configuracao
echo.
pause
hbmk2 hbnfe -xhb %1 %2 %3 %4
