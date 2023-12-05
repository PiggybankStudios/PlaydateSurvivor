@echo off

set RunGame=1

set PlaydateSdkDirectory=%PLAYDATE_SDK_PATH%
set PdcExeName=%PlaydateSdkDirectory%\bin\pdc

echo [Packaging...]
%PdcExeName% -sdkpath "%PlaydateSdkDirectory%" "..\src" "PlaydateSurvivor.pdx"

if "%RunGame%"=="1" (
	echo [Running Game...]
	%PlaydateSdkDirectory%\bin\PlaydateSimulator.exe "PlaydateSurvivor.pdx"
) else (
	echo [Done!]
)
