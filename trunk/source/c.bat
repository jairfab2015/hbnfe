@echo off
echo enquanto n�o terminar o ajuste -w3 -es2
echo a op��o � compilar digitando c -w0 -es0
echo.
echo Estes arquivos de compilacao foram criados apenas pra teste
echo.
echo fazem parte do Harbour hbcurl.ch, hbcompat.ch, hbxml.ch
echo apague desta pasta e use os arquivos do seu pr�prio Harbour
echo.
echo o arquivo hbnfe.ch � o mesmo da pasta ..\include copiado s� pra facilitar compila��o
echo.
echo no hbp est� usando workdir=d:\temp, ajuste para sua configura��o
echo.
pause
hbmk2 hbnfe -xhb %1 %2 %3 %4
