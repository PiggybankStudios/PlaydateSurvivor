@echo off

set RunGame=1

set PlaydateSdkDirectory=%PLAYDATE_SDK_PATH%
set PdcExeName=%PlaydateSdkDirectory%\bin\pdc

echo [Running PDC...]
%PdcExeName% -sdkpath "%PlaydateSdkDirectory%" "..\src" "PlaydateSurvivor.pdx"
echo [Done!]

if "%RunGame%"=="1" (
	%PlaydateSdkDirectory%\bin\PlaydateSimulator.exe "PlaydateSurvivor.pdx"
)
