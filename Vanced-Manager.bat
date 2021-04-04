@echo off
setlocal enabledelayedexpansion
tasklist /fi "IMAGENAME eq cmd.exe" /fi "WINDOWTITLE eq Vanced Manager for Windows" |find "No tasks" >nul || goto programAlreadyRunning
pushd "%~dp0"
title Vanced Manager for Windows
set tryConnect=1
set mSpinner=.
mode con cols=85 lines=22


REM   _________To do list__________

REM isRoot
REM Buggy mode con animation
REM Before "installed" for microG and Vanced, call the isInstalled function. If not, display error.
REM Add YouTube Music UI
REM Download / Install UI
REM Fix for loop goto nextline crap


REM   _________Manager v1.1__________

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
echo. [%~1m
echo     %~2
echo    ^|%~3^|
echo    ^|%~4^|
echo    ^|%~5^|
echo. [0m
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
ping -n 1 www.google.com > nul 2>&1 && (set tryConnect=1 & cls & exit /b)
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
	echo Downloading ADB... [0%%]
	if not exist Files\adb md Files\adb
	set adbDestination=Files\adb\adb.zip
	powershell -Command "& { Get-BitsTransfer -Name "downloadADB*"| Complete-BitsTransfer }
	powershell -Command "& { $ProgressPreference = 'SilentlyContinue' ;Start-BitsTransfer -Source "https://dl.google.com/android/repository/platform-tools_r31.0.0-windows.zip" -Destination "$env:adbDestination" -Asynchronous -DisplayName downloadADB *>$null;}" 
	set ADBProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadADB"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadADB"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
	:ADBLoop
	FOR /F "tokens=*" %%a IN ('%ADBProgressBar%') DO (
		cls 
		echo Downloading ADB... [%%a%%]
		if %%a == 100 cls & goto endADBLoop
	)
	
	goto ADBLoop
	:endADBLoop
	echo Downloading ADB... [100%%]
	powershell -Command "& { Get-BitsTransfer -Name "downloadADB"| Complete-BitsTransfer }
	
	cls
	echo Transferring ADB...
	
	set zipfile=%~dp0Files\adb\adb.zip\platform-tools
	set deletedZip=Files\adb\adb.zip*
	set dst=%~dp0Files\adb

	powershell.exe -nologo -noprofile -command "& {$files='adb.exe', 'AdbWinApi.dll', 'AdbWinUsbApi.dll' ;$app = New-Object -COM 'Shell.Application'; $app.NameSpace("$env:zipfile").Items() | ? { $files -contains $_.Name } | %% { $app.Namespace("$env:dst").MoveHere($_, 4);}}"
	powershell -command "& { Remove-Item ("$env:deletedZip")}"	
	!adb! start-server 2>nul
	goto beginning
	

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
for /f tokens^=3^ skip^=%microgline%^ delims^=^"^  %%a in (Files\latest.json) do set latestMicroGVersion=%%a& goto :nextline2
:nextline2
for /f "tokens=1 delims=[] " %%a in ('FIND /n """music""" Files\latest.json') do set musicline=%%a
for /f tokens^=3^ skip^=%musicline%^ delims^=^"^  %%a in (Files\latest.json) do set latestMusicVersion=%%a& goto :nextline3
:nextline3

exit /b



echo this might work lol

:isVancedInstalled

echo hypothetically without the bug, since it is a new commit
pause
set isVancedInstalledparameter=0
set VancedUpdateInstall=  Install
set currentVancedVersion=None
for /f "tokens=*" %%a IN ('%adb% shell pm list packages ^|find "com.vanced.android.youtube"') DO (
	set isVancedInstalledparameter=1
	set VancedUpdateInstall=   Update
	for /f "tokens=2 delims==" %%b IN ('%adb% shell dumpsys package com.vanced.android.youtube ^|findstr "versionName"') DO (
		set currentVancedVersion=%%b && if %%b==%latestVancedVersion% set VancedUpdateInstall=Reinstall
	)
	
)
exit /b



:isMicroGInstalled

set isMicroGInstalledparameter=0
set MicroGUpdateInstall=  Install
set currentMicroGVersion=None         

for /f "tokens=*" %%a IN ('%adb% shell pm list packages ^|find "com.mgoogle.android.gms"') DO (
	set isMicroGInstalledparameter=1
	set MicroGUpdateInstall=   Update
	for /f "tokens=2 delims==" %%b IN ('%adb% shell dumpsys package com.mgoogle.android.gms ^|findstr "versionName"') DO (
		set currentMicroGVersion=%%b && if %%b==%latestMicroGVersion% set MicroGUpdateInstall=Reinstall
	)
	
)
exit /b


:isMusicInstalled

set isMusicInstalledparameter=0
set MusicUpdateInstall=  Install
set currentMusicVersion=None         

for /f "tokens=*" %%a IN ('%adb% shell pm list packages ^|find "com.vanced.android.apps.youtube.music"') DO (
	set isMusicInstalledparameter=1
	set musicUpdateInstall=   Update
	for /f "tokens=2 delims==" %%b IN ('%adb% shell dumpsys package com.vanced.android.apps.youtube.music ^|findstr "versionName"') DO (
		set currentMusicVersion=%%b && if %%b==%latestMusicVersion% set MusicUpdateInstall=Reinstall
	)
	
)
exit /b


:Manager

call :isVancedInstalled
call :isMicroGInstalled
call :isMusicInstalled
call :getLatestVersions
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
echo [94m     MicroG [0m
echo.
echo       Latest: %latestMicroGVersion%                  [0m%MicroGUpdateInstall% [0m[[93m2[0m]
echo       Installed: %currentMicroGVersion%
echo.
echo    --------------------------------------------------------- 
echo   ===========================================================
echo.
echo     Refresh [[93mR[0m]   Quit [[93mQ[0m]
CHOICE /C 12rq /N
IF %ERRORLEVEL% EQU 4 goto EXIT
IF %ERRORLEVEL% EQU 3 goto beginning
IF %ERRORLEVEL% EQU 2 call :updateMicroG
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
echo Downloading latest Vanced... [0%%]
echo.	
if not exist Files\vanced md Files\vanced\v%latestVancedVersion%
rem set latestVancedVersion=15.43.32
set archURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Arch/split_config.%arch%.apk
set langURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Language/split_config.%lang%.apk
set themeURL=https://vancedapp.com/api/v1/apks/v%latestVancedVersion%/%isRoot%/Theme/%theme%.apk

set archDestination=Files\vanced\v%latestVancedVersion%\config.%arch%.apk
set langDestination=Files\vanced\v%latestVancedVersion%\split_config.%lang%.apk
set themeDestination=Files\vanced\v%latestVancedVersion%\YouTube_%latestVancedVersion%_API21nodpiv%theme%-v2.1.0-vanced.apk

powershell -Command "& { Get-BitsTransfer -Name "downloadVanced*"| Complete-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "$env:archURL", "$env:langURL", "$env:themeURL" -Destination "$env:archDestination", "$env:langDestination", "$env:themeDestination" -Asynchronous -DisplayName downloadVanced *>$null;}"
set vancedProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadVanced"| select-object -expandProperty BytesTotal; $transferredBytes = Get-BitsTransfer -Name "downloadVanced"| select-object -expandProperty BytesTransferred; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:vancedLoop
FOR /F "tokens=*" %%a IN ('%vancedProgressBar%') DO (
cls
echo Downloading latest YouTube Vanced... [%%a%%]
if %%a == 100 cls & goto endVancedLoop
)

goto vancedLoop
:endVancedLoop
echo Downloading latest YouTube Vanced... [100%%]
powershell -Command "& { Get-BitsTransfer -Name "downloadVanced"| Complete-BitsTransfer }	
echo Download Complete
echo.
cls 
echo Installing...
%adb% install-multiple -r %themeDestination% %archDestination% %langDestination% 1>nul
cls
echo Installed
ping 127.0.0.1 -n 2 >nul
exit /b




:updateMicroG

call :checkInternet
call :checkADB
cls
echo Downloading latest MicroG... [0%%]
echo.
if not exist Files\microg md Files\microg\v%latestMicroGVersion%
powershell -Command "& { Get-BitsTransfer -Name "downloadMicroG*"| Complete-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue' *>$null;Start-BitsTransfer -Source "https://github.com/YTVanced/VancedMicroG/releases/latest/download/microg.apk" -Destination "Files\microG\v%latestMicroGVersion%\microG.apk" -Asynchronous -DisplayName downloadMicroG *>$null;}" 
set microgProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadMicroG"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadMicroG"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:microgLoop
FOR /F "tokens=*" %%a IN ('%microgProgressBar%') DO (
cls 
echo Downloading latest MicroG... [%%a%%]
if %%a == 100 cls & goto endMicrogLoop
)

goto microgLoop
:endMicrogLoop
echo Downloading latest MicroG... [100%%]
powershell -Command "& { Get-BitsTransfer -Name "downloadMicroG"| Complete-BitsTransfer }	
echo Download Complete
echo.
cls
echo Installing...
%adb% install Files\microG\v%latestMicroGVersion%\microg.apk 1>nul
cls
echo Installed
ping 127.0.0.1 -n 2 >nul
exit /b



:updateMusic

call :checkInternet
call :checkADB
call :root isRoot
call :arch arch

set archURL=https://vancedapp.com/api/v1/music/v%latestMusicVersion%/stock/%arch%.apk
set rootURL=https://vancedapp.com/api/v1/music/v%latestMusicVersion%/%isRoot%.apk

set archDestination=Files\music\v%latestMicroGVersion%\%arch%.apk
set rootDestination=Files\music\v%latestMicroGVersion%\%isRoot%.apk
cls
echo Downloading latest Music... [0%%]
echo.
if not exist Files\music md Files\music\v%latestMusicVersion%
powershell -Command "& { Get-BitsTransfer -Name "downloadMusic*"| Complete-BitsTransfer }
powershell -Command "& { $ProgressPreference = 'SilentlyContinue';Start-BitsTransfer -Source "$env:archURL", "$env:rootURL" -Destination "$env:archDestination", "$env:rootDestination" -Asynchronous -DisplayName downloadMusic *>$null;}"
set musicProgressBar= powershell -Command "& {$totalBytes = Get-BitsTransfer -Name "downloadMusic"| select-object -expandProperty BytesTotal ; $transferredBytes = Get-BitsTransfer -Name "downloadMusic"| select-object -expandProperty BytesTransferred ; $temp=($transferredBytes/$totalBytes); $temp2=[math]::round($temp,2)*100; write-output $temp2;}"
:musicLoop
FOR /F "tokens=*" %%a IN ('%musicProgressBar%') DO (
cls 
echo Downloading latest Music... [%%a%%]
if %%a == 100 cls & goto endMusicLoop
)

goto musicLoop
:endMusicLoop
echo Downloading latest Music... [100%%]
powershell -Command "& { Get-BitsTransfer -Name "downloadMusic"| Complete-BitsTransfer }	
echo Download Complete
echo.
cls
echo Installing...
%adb% install-multiple -r %archDestination% %rootDestination% 1>nul
cls
echo Installed
ping 127.0.0.1 -n 2 >nul
exit /b



:root

set %~1=nonroot
for /f "tokens=*" %%a IN ('%adb% shell su 2^>nul ^|find "#"') DO (
	CHOICE /C 12 /N /M "Select [1] for nonroot [2] for root"
	IF %ERRORLEVEL% EQU 2 set %~1=nonroot
)
exit /b


:theme

CHOICE /C 12 /N /M "Select [1] for Dark [2] for Black"
IF %ERRORLEVEL% EQU 2 set %~1=black
IF %ERRORLEVEL% EQU 1 set %~1=dark
exit /b



:arch

for /f "tokens=*" %%a IN ('%adb% shell getprop ro.product.cpu.abi') DO (set arch=%%a)
set %~1=%arch:-=_%
exit /b



:language

set %~1=en
exit /b




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
