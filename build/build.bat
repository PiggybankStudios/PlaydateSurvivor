@echo off

set PlaydateSdkDirectory=%PLAYDATE_SDK_PATH%
set PdcExeName=%PlaydateSdkDirectory%\bin\pdc

echo [Running PDC...]
%PdcExeName% -sdkpath "%PlaydateSdkDirectory%" "..\src" "PlaydateSurvivor.pdx"
echo [Done!]
