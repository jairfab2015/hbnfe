hbmk2 -inc testes .\source\*.prg -otesteNfe.exe -lhbwin -lhbct -lhbhpdf -llibhpdf -lhbzebra -lpng -lhbcurl -lhbcurls -llibcurl > error.log 2>&1
if errorlevel 1 goto BUILD_ERR

:BUILD_OK
   goto EXIT


:BUILD_ERR
   notepad error.log
   goto EXIT
