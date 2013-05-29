hbmk2 -trace -INC -mt testeNfe_HwGui.prg .\source\*.prg -otesteNFeHwGui.exe testeNfe_hwgui.hbc > error.log 2>&1
if errorlevel 1 goto BUILD_ERR

:BUILD_OK
   goto EXIT


:BUILD_ERR
   notepad error.log
   goto EXIT
