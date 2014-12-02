@echo off
echo enquanto não terminar o ajuste -w3 -es2
echo a opção é compilar digitando c -w0 -es0
echo.
echo Estes arquivos de compilacao foram criados apenas pra teste
echo.
echo fazem parte do Harbour hbcurl.ch, hbcompat.ch, hbxml.ch
echo apague desta pasta e use os arquivos do seu próprio Harbour
echo.
echo o arquivo hbnfe.ch é o mesmo da pasta ..\include copiado só pra facilitar compilação
echo.
echo no hbp está usando workdir=d:\temp, ajuste para sua configuração
echo.
pause
hbmk2 hbnfe -xhb %1 %2 %3 %4
