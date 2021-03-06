@echo off
mode con cols=85 lines=28
setlocal enabledelayedexpansion
tasklist /fi "IMAGENAME eq cmd.exe" /fi "WINDOWTITLE eq Vanced Manager for Windows" |find "No tasks" >nul || goto programAlreadyRunning
title Vanced Manager for Windows
pushd "%~dp0"
set tryConnect=1
set mSpinner=.


REM   _________To do list__________

REM isRoot
REM Before "installed" for microG and Vanced, call the isInstalled function. If not, display error.
REM Instructions on how to enable USB debugging
REM Internet UI
REM download UI for ADB



REM   _________Manager v1.1__________

REM lang
REM Uninstall microg and vanced
REM Uninstall Youtube (not vanced)
REM Works offline
REM Install specific versions
REM Options menu



:beginning

cls

call :isAdbInstalled
call :checkADB
call :deviceConnected
call :Manager



:UI

echo.
echo     [1mVanced Manager[0m
echo   ===========================================================
echo    ---------------------------------------------------------
echo.
echo.
echo.
echo.
echo.
echo. [%~1m
echo     %~2
echo    ^|%~3^|
echo    ^|%~4^|
echo    ^|%~5^|
echo. [0m
echo.
echo.
echo.
echo.
echo.
echo.
echo    ---------------------------------------------------------
echo   ===========================================================
echo.
exit /b



:checkInternet

set mSpinner=%mSpinner%.
if %mSpinner%'==....' (set mSpinner=.)
ping -n 1 8.8.8.8 > nul 2>&1 && (set tryConnect=1 &  exit /b)
REM add "cls &"
cls

set "checkInternet2=____________________________"
set "checkInternet3=                            "
set "checkInternet4= Internet is not connected. "
call :UI "96", "!checkInternet2!", "!checkInternet3!", "!checkInternet4!", "!checkInternet2!"

set /a "tryConnect+=1"

if not %tryConnect%==10 (
	echo Retrying%mSpinner%
	ping 127.0.0.1 -n 2 >nul
	goto checkInternet
	)

CHOICE /C RQ /N /M "Failed to connect. Select [R] Retry or [Q] Quit"
IF %ERRORLEVEL% EQU 2 goto exit
IF %ERRORLEVEL% EQU 1 set tryConnect=1 & goto checkInternet



:isAdbInstalled

set adb=Files\adb\adb.exe -d
for /f "tokens=*" %%a in ('adb version 2^>nul ^|find "Android"') do (
	set adb=adb
	!adb! start-server 2>nul
	exit /b
)
set filesMissing=0
if not exist Files\adb\adb.exe set filesMissing=1
if not exist Files\adb\AdbWinApi.dll set filesMissing=1
if not exist Files\adb\AdbWinUsbApi.dll set filesMissing=1
if %filesMissing%==1 (

	set "isAdbInstalled2=___________________________________________________________________________"
	set "isAdbInstalled3=                                                                           "
	set "isAdbInstalled4= In order for this program to work properly, it will need to download ADB. "
	call :UI "96", "!isAdbInstalled2!", "!isAdbInstalled3!", "!isAdbInstalled4!", "!isAdbInstalled2!"
	
	echo     Download ADB [[93m1[0m]   Quit [[93mQ[0m]
	CHOICE /C 1Q /N
	IF !ERRORLEVEL! EQU 2 goto :EXIT
	call :checkInternet
	cls
	call :downloadUI "0","ADB"
	if not exist Files\adb md Files\adb
	set adbDestination=Files\adb\adb.zip
	powershell -Command "& { Get-BitsTransfer -Name "downloadADB*"| Remove-BitsTransfer }
	powershell -Command "& { $ProgressPreference = 'SilentlyContinue' ;Start-BitsTransfer -Source "https://dl.google.com/android/repository/platform-tools_r31.0.0-windows.zip" -Destination "$env:adbDestination" -Asynchronous -DisplayName downloadADB *>$null;}" 
	set ADBProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadADB"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadADB"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
	:ADBLoop
	FOR /F "tokens=*" %%a IN ('%ADBProgressBar%') DO (

		call :downloadUI "%%a","ADB"
		if %%a == 100 goto endADBLoop
	)
	
	goto ADBLoop
	:endADBLoop
	powershell -Command "& { Get-BitsTransfer -Name "downloadADB"| Complete-BitsTransfer }
	call :installUI "call :adbFileTransfer"
	rem echo Transferring ADB...
	goto beginning


	:adbFileTransfer
	set "zipfile=%~dp0Files\adb\adb.zip\platform-tools"
	set deletedZip=Files\adb\adb.zip*
	set "dst=%~dp0Files\adb"

	powershell.exe -nologo -noprofile -command "& {$files='adb.exe', 'adb', 'AdbWinApi.dll', 'AdbWinUsbApi.dll' ;$app = New-Object -COM 'Shell.Application'; $app.NameSpace("$env:zipfile").Items() | ? { $files -contains $_.Name } | %% { $app.Namespace("$env:dst").MoveHere($_, 0x14);}}"
	powershell -command "& { Remove-Item ("$env:deletedZip")}"	
	!adb! start-server 2>nul
	exit /b

	

)
!adb! start-server 2>nul
exit /b



:checkADB

for /f "tokens=1-5" %%a in ('%adb% devices') do set "isAdbConnected=%%b"
if %isAdbConnected% ==device ( exit /b )
if %isAdbConnected% ==of ( goto noDevice )
if %isAdbConnected% ==unauthorized ( goto unauthorized ) else ( echo error adb )
echo Something went wrong, press any key to exit
pause >nul
goto EXIT



:noDevice

set "noDevice2=_____________________________________________________________________"
set "noDevice3=                                                                     "
set "noDevice4= Please make sure device is plugged in and USB Debugging is enabled. "
call :UI "31", "!noDevice2!", "!noDevice3!", "!noDevice4!", "!noDevice2!"
echo       Refresh [[93mR[0m]   Quit [[93mQ[0m]
CHOICE /C RQ /N
IF %ERRORLEVEL% EQU 2 goto EXIT
IF %ERRORLEVEL% EQU 1 goto beginning


:unauthorized

set "deviceunauthorized2=_________________________________"
set "deviceunauthorized3=                                 "
set "deviceunauthorized4= Please authorize USB Debugging. "
call :UI "35", "!deviceunauthorized2!", "!deviceunauthorized3!", "!deviceunauthorized4!", "!deviceunauthorized2!"
echo       Refresh [[93mR[0m]   Quit [[93mQ[0m]
CHOICE /C RQ /N
IF %ERRORLEVEL% EQU 2 goto EXIT
IF %ERRORLEVEL% EQU 1 goto beginning


:deviceConnected

set "deviceConnected2=_________________________________"
set "deviceConnected3=                                 "
set "deviceConnected4= Device connected sucsessfully^^^!^^^! "
call :UI "34", "!deviceConnected2!", "!deviceConnected3!", "!deviceConnected4!", "!deviceConnected2!"
exit /b



:getLatestVersions

if not exist Files md Files
call :checkInternet
powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "https://vancedapp.com/api/v1/latest.json" -Destination "'Files\latest.json'";$ProgressPreference = 'Continue';}"
for /f "tokens=1 delims=[] " %%a in ('FIND /n """vanced""" Files\latest.json') do set vancedline=%%a
for /f tokens^=3^ skip^=%vancedline%^ delims^=^"^  %%a in (Files\latest.json) do set latestVancedVersion=%%a& goto :nextline
:nextline
for /f "tokens=1 delims=[] " %%a in ('FIND /n """microg""" Files\latest.json') do set microgline=%%a
for /f tokens^=4^ skip^=%microgline%^ delims^=^"^  %%a in (Files\latest.json) do set latestMicroGVersion=%%a& goto :nextline2
:nextline2
for /f "tokens=1 delims=[] " %%a in ('FIND /n """music""" Files\latest.json') do set musicline=%%a
for /f tokens^=4^ skip^=%musicline%^ delims^=^"^  %%a in (Files\latest.json) do set latestMusicVersion=%%a& goto :nextline3
:nextline3

exit /b



:isVancedInstalled
call :isAppInstalled "Vanced", "com.vanced.android.youtube"
exit /b
:isMicroGInstalled
call :isAppInstalled "MicroG", "com.mgoogle.android.gms"
exit /b
:isMusicInstalled
call :isAppInstalled "Music", "com.vanced.android.apps.youtube.music"
exit /b


:isAppInstalled
set is%~1Installedparameter=0
set %~1UpdateInstall=  Install
set current%~1Version=None         


for /f "tokens=*" %%a IN ('%adb% shell pm list packages ^|find "%~2"') DO (
	set is%~1Installedparameter=1
	set %~1UpdateInstall=   Update
	for /f "tokens=2 delims==" %%b IN ('%adb% shell dumpsys package %~2 ^|findstr "versionName"') DO (
	 	set current%~1Version=%%b && if %%b==!latest%~1Version! set %~1UpdateInstall=Reinstall
	)
	
)
exit /b


:Manager

call :getLatestVersions
call :isVancedInstalled
call :isMicroGInstalled
call :isMusicInstalled
cls
echo.
echo     [1mVanced Manager[0m
echo   ===========================================================
echo    ---------------------------------------------------------
echo [94m     YouTube Vanced [0m
echo.
echo       Latest: !latestVancedVersion!                       [0m%VancedUpdateInstall%[0m [[93m1[0m]
echo       Installed: %currentVancedVersion%
echo.
echo    ---------------------------------------------------------
echo [94m     YouTube Music [0m
echo.
echo       Latest: %latestMusicVersion%                        [0m%MusicUpdateInstall% [0m[[93m2[0m]
echo       Installed: %currentMusicVersion%
echo.
echo    --------------------------------------------------------- 
echo [94m     MicroG [0m
echo.
echo       Latest: %latestMicroGVersion%                  [0m%MicroGUpdateInstall% [0m[[93m3[0m]
echo       Installed: %currentMicroGVersion%
echo.
echo    --------------------------------------------------------- 
echo   ===========================================================
echo.
echo     Refresh [[93mR[0m]   Vanced Website [[93mV[0m]   Quit [[93mQ[0m]
CHOICE /C 123rvq /N
IF %ERRORLEVEL% EQU 6 goto EXIT
IF %ERRORLEVEL% EQU 5 start "" https://vancedapp.com/
IF %ERRORLEVEL% EQU 4 goto beginning
IF %ERRORLEVEL% EQU 3 call :updateMicroG
IF %ERRORLEVEL% EQU 2 call :updateMusic
IF %ERRORLEVEL% EQU 1 call :updateVanced
goto Manager
EXIT /b



:updateVanced

call :checkInternet	
call :checkADB
call :root isRoot
call :theme theme
call :arch arch
call :language lang

cls
call :downloadUI "0","YouTube Vanced"
echo.	
if not exist Files\vanced\v%latestVancedVersion% md Files\vanced\v%latestVancedVersion%
rem set latestVancedVersion=15.43.32
set archURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Arch/split_config.%arch%.apk
set langURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Language/split_config.%lang%.apk
set themeURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Theme/%theme%.apk

set archDestination=Files\vanced\v%latestVancedVersion%\config.%arch%.apk
set langDestination=Files\vanced\v%latestVancedVersion%\split_config.%lang%.apk
set themeDestination=Files\vanced\v%latestVancedVersion%\YouTube_%latestVancedVersion%_API21nodpiv%theme%-v2.1.0-vanced.apk

powershell -Command "& { Get-BitsTransfer -Name "downloadVanced*"| Remove-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "$env:archURL", "$env:langURL", "$env:themeURL" -Destination "$env:archDestination", "$env:langDestination", "$env:themeDestination" -Asynchronous -DisplayName downloadVanced *>$null;}"
set vancedProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadVanced"| select-object -expandProperty BytesTotal; $transferredBytes = Get-BitsTransfer -Name "downloadVanced"| select-object -expandProperty BytesTransferred; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:vancedLoop
FOR /F "tokens=*" %%a IN ('%vancedProgressBar%') DO (

	call :downloadUI "%%a","YouTube Vanced"
	if %%a == 100 goto endVancedLoop
)

goto vancedLoop
:endVancedLoop
powershell -Command "& { Get-BitsTransfer -Name "downloadVanced"| Complete-BitsTransfer }	
call :installUI "%adb% install-multiple -r %themeDestination% %archDestination% %langDestination% 1>nul"
exit /b




:updateMicroG

call :checkInternet
call :checkADB

cls
call :downloadUI "0","MicroG"
echo.
if not exist Files\microg\v%latestMicroGVersion% md Files\microg\v%latestMicroGVersion%
powershell -Command "& { Get-BitsTransfer -Name "downloadMicroG*"| Remove-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue' *>$null;Start-BitsTransfer -Source "https://github.com/YTVanced/VancedMicroG/releases/latest/download/microg.apk" -Destination "Files\microG\v%latestMicroGVersion%\microG.apk" -Asynchronous -DisplayName downloadMicroG *>$null;}" 
set microgProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadMicroG"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadMicroG"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:microgLoop
FOR /F "tokens=*" %%a IN ('%microgProgressBar%') DO (

	call :downloadUI %%a, MicroG
	if %%a == 100 goto endMicrogLoop
)

goto microgLoop
:endMicrogLoop
powershell -Command "& { Get-BitsTransfer -Name "downloadMicroG"| Complete-BitsTransfer }	
call :installUI "%adb% install Files\microG\v%latestMicroGVersion%\microg.apk 1>nul"
exit /b



:updateMusic

REM The Arch APK is most likely unnecessary 
call :checkInternet
call :checkADB
call :root isRoot
rem call :arch arch

rem set archURL=https://vancedapp.com/api/v1/music/v%latestMusicVersion%/stock/%arch%.apk
set rootURL=https://vancedapp.com/api/v1/music/v%latestMusicVersion%/%isRoot%.apk

rem set archDestination=Files\music\v%latestMusicVersion%\%arch%.apk
set rootDestination=Files\music\v%latestMusicVersion%\%isRoot%.apk

cls
call :downloadUI "0","Vanced Music"
echo.
if not exist Files\music\v%latestMusicVersion% md Files\music\v%latestMusicVersion%
powershell -Command "& { Get-BitsTransfer -Name "downloadMusic*"| Remove-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "$env:rootURL" -Destination "$env:rootDestination" -Asynchronous -DisplayName downloadMusic *>$null;}"
rem powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "$env:archURL", "$env:rootURL" -Destination "$env:archDestination", "$env:rootDestination" -Asynchronous -DisplayName downloadMusic *>$null;}"
set musicProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadMusic"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadMusic"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:musicLoop
FOR /F "tokens=*" %%a IN ('%musicProgressBar%') DO (

	call :downloadUI "%%a","Vanced Music"
	if %%a == 100 goto endMusicLoop
)

goto musicLoop
:endMusicLoop
powershell -Command "& { Get-BitsTransfer -Name "downloadMusic"| Complete-BitsTransfer }	
call :installUI "%adb% install %rootDestination% 1>nul"
exit /b



:downloadUI
SETLOCAL ENABLEDELAYEDEXPANSION
SET ProgressPercent=%~1
SET /A NumBars=%ProgressPercent%/4
SET /A NumSpaces=25-%NumBars%

SET Meter=

FOR /L %%A IN (%NumBars%,-1,1) DO SET Meter=!Meter!I
FOR /L %%A IN (%NumSpaces%,-1,1) DO SET Meter=!Meter! 

cls

echo.
echo     [94m%~2 [0m
echo   ===========================================================
echo    ---------------------------------------------------------
echo       Downloading...
echo.
echo       Progress:  [%Meter%]  %ProgressPercent%%%
echo.
if !ProgressPercent!==100 (echo       Download Complete.) else (echo.)
echo    ---------------------------------------------------------
echo   ===========================================================
ENDLOCAL
exit /b

:installUI
echo    ---------------------------------------------------------
echo       Installing...
echo.
%~1
echo.
echo       Installed.
echo    ---------------------------------------------------------
echo   ===========================================================

ping 127.0.0.1 -n 2 >nul
exit /b




:root

cls
set %~1=nonroot
for /f "tokens=*" %%a IN ('%adb% shell su 2^>nul ^|find "#"') DO (
	CHOICE /C 12 /N /M "Select [1] for nonroot [2] for root"
	IF %ERRORLEVEL% EQU 2 set %~1=nonroot
)
exit /b


:theme
cls
echo.
echo.
echo    Please select your theme:
echo.
echo   __________       __________
echo   [100m          [0m                
echo   [100m DARK [[93m1[0m[100m] [0m     [0m   BLACK [[93m2[0m]   
echo   [100m__________[0m       __________
echo.
CHOICE /C 12 /N
IF %ERRORLEVEL% EQU 2 set %~1=black
IF %ERRORLEVEL% EQU 1 set %~1=dark
exit /b



:arch

cls
for /f "tokens=*" %%a IN ('%adb% shell getprop ro.product.cpu.abi') DO (set arch=%%a)
set %~1=%arch:-=_%
exit /b



:language

cls
set %~1=en
exit /b





:programAlreadyRunning

set "programAlreadyRunning2=_____________________________________"
set "programAlreadyRunning3=                                     "
set "programAlreadyRunning4= Error^^^!^^^! Program is already running. "
call :UI "31", "!programAlreadyRunning2!", "!programAlreadyRunning3!", "!programAlreadyRunning4!", "!programAlreadyRunning2!"
echo       Press any key to exit
pause >nul
goto EXIT



:EXIT

cls
echo.
echo.
echo    ====================================
echo.
echo    - - - - Peehee Entertainment - - - -
echo.
echo    ====================================
echo.
echo Press any key to exit. . .
!adb! kill-server 2<nul
pause >nul
exit
