@echo off

set LocalPath=none
set dracuser=none
set drachost=none
set kmport=none
set uiport=none
set password=none

set /a ArgumentIndex=1
set /a BeginningIndex=0
set KeyToken=none

goto GetArguments

:GetArguments
if "%~1"=="" goto ArgumentDefine
set arg%ArgumentIndex%=%1

set /a BeginningIndex=%ArgumentIndex%/2 - BeginningIndex
if not %BeginningIndex%==0 (
	set cm%KeyToken%=%~1
) else (
	set KeyToken=%~1
)
shift
set /a ArgumentIndex=%ArgumentIndex%+1
goto GetArguments

:ArgumentDefine
if not %ArgumentIndex%==11 goto help
set LocalPath=%cm-d%
set dracuser=%cm-u%
set uiport=%cm-w%
set kmport=%cm-k%
set drachost=%cm-h%
goto main

:help
echo hello
exit /B

:main
cd %LocalPath%
NET SESSION >nul 2>&1
IF %ERRORLEVEL%==2 (
	goto Request-UAC
)

echo Setting up preinstallation environment
echo =============================================================
if not exist "%LocalPath%\lib" (
	echo Creating library location...
	mkdir "%LocalPath%\lib"
	if %errorlevel%==1 goto Unable-lib
	echo Library was successfully created!
)
if exist "C:\Program Files\7-Zip\7z.exe" (
echo Found Required 3rd Party Library: 7-Zip x64
) else (
echo Downloading 3rd Party library: https://www.7-zip.org/a/7z2201-x64.exe
powershell -Command "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z2201-x64.exe', '%LocalPath%\7z2201-x64.exe')"
start /wait 7z2201-x64.exe /S
)
if exist "%LocalPath%\lib\nc.exe" (
echo Found Required 3rd Party Library: Netcat-Windows x64
) else (
echo Downloading 3rd Party library: https://github.com/mt-code/netcat-windows/raw/master/nc64.exe
powershell -Command "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(New-Object System.Net.WebClient).DownloadFile('https://github.com/mt-code/netcat-windows/raw/master/nc64.exe', '%LocalPath%\lib\nc.exe')"
)
if exist "%LocalPath%\JRE\" (
echo Found Required 3rd Party Install: Java JRE x64
) else (
echo Installation of JRE not found, this is required when attempting to excute the iDRAC Terminal.
echo Please install at https://www.oracle.com/java/technologies/javase/javase7-archive-downloads.html
echo.
echo It is recommended to use Server JRE 7u80 or Java SE Runtime Environment 7u80
echo  - Make sure this installation is extracted from tar.gz and the folder is renamed to 'JRE'
)

echo.
echo Testing connection
echo =============================================================

echo Testing connection with %drachost%
ping %drachost% -n 1 >nul
IF %errorlevel%==1 goto Unable-ui
echo Testing connection with %drachost%:%uiport%
"%LocalPath%\lib\nc.exe" -v -z -w 3 %drachost% %uiport%
IF %errorlevel%==1 goto Unable-ui
echo Testing connection with %drachost%:%kmport%
"%LocalPath%\lib\nc.exe" -v -z -w 3 %drachost% %kmport%
IF %errorlevel%==1 goto Unable-kvm 
echo.
echo Downloading Required Libraries
echo =============================================================
call :Download-avctKVM
echo.
call :Download-avmWinLib
echo.
call :Download-avctKVMIO
echo.
echo Cleaning Library...
echo =============================================================

if exist "%LocalPath%\lib\avctVMWin64.jar" (
echo Deleting Archive: 'lib\avctVMWin64.jar'
del "%LocalPath%\lib\avctVMWin64.jar"
)
if exist "%LocalPath%\lib\avctKVMIOWin64.jar" (
echo Deleting Archive: 'lib\avctKVMIOWin64.jar'
del "%LocalPath%\lib\avctKVMIOWin64.jar"
)
if exist "%LocalPath%\7z2201-x64.exe" (
echo Deleting Archive: '7z2201-x64.exe'
del 7z2201-x64.exe
)
echo.
echo Excuting Java iDRAC Console...
echo =============================================================
echo Connecting to %dracuser%@%drachost%:%kmport%
set "psCommand=powershell -Command "$pword = read-host 'Enter Password' -AsSecureString ; ^
    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set dracpwd=%%p
"%LocalPath%\jre\bin\java" -cp .\lib\avctKVM.jar -Djava.library.path=.\lib com.avocent.idrac.kvm.Main ip="%drachost%" kmport="%kmport%" vport="%kmport%" user="%dracuser%" passwd="%dracpwd%" apcp=1 version=2 vmprivilege=true "helpurl=https://%drachost%:%uiport%/help/contents.html" >> log.txt
pause
exit /b 1

:Unable-lib
echo Can't create "%LocalPath%\lib"
timeout /t 5
exit /b 6020

:Unable-host
echo Can't communicate to iDRAC host!
timeout /t 5
exit /b 6025

:Unable-ui
echo Can't communicate to WebUI at port %uiport%!
timeout /t 5
exit /b 6030

:Unable-kvm
echo Can't communicate to KVM at port %kmport%!
timeout /t 5
exit /b 6035

:unzip <ExtractLocation> <WantedFile> <File>
"C:\Program Files\7-Zip\7z.exe" -y e %3 -ir!*%2 -o%1 >nul 2>&1
EXIT /B 0

:Check-avctKVM
echo -----------------------------
echo Checking Integrity: 'lib\avctKVM.jar'
FOR /F "usebackq" %%A IN ('%LocalPath%\lib\avctKVM.jar') DO set size=%%~zA
if not "%size%"=="1006154" (
	echo File Integrity: 'lib\avctKVM.jar' has Failed...
	del %LocalPath%\lib\avctKVM.jar
	call :Download-avctKVM
	call :Check-avctKVM
	EXIT /B 0
) else (
echo File Integrity: 'lib\avctKVM.jar' has Passed...
)
EXIT /B 0

:Download-avctKVM
if exist "%LocalPath%\lib\avctKVM.jar" (
echo Found Previously Library: 'lib\avctKVM.jar'
) else (
echo Downloading library: https://%drachost%:%uiport%/software/avctKVM.jar
powershell -Command "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(New-Object System.Net.WebClient).DownloadFile('https://%drachost%:%uiport%/software/avctKVM.jar', '%LocalPath%\lib\avctKVM.jar')"
)
call :Check-avctKVM
EXIT /B 0

:Check-avmWinLib
echo -----------------------------
echo Checking Integrity: 'lib\avmWinLib.dll'
FOR /F "usebackq" %%A IN ('%LocalPath%\lib\avmWinLib.dll') DO set size=%%~zA
if not "%size%"=="210944" (
	echo File Integrity: 'lib\avmWinLib.dll' has Failed...
	del %LocalPath%\lib\avmWinLib.dll
	call :Download-avmWinLib
	call :Check-avmWinLib
	EXIT /B 0
) else (
echo File Integrity: 'lib\avmWinLib.dll' has Passed...
)
EXIT /B 0

:Download-avmWinLib
if exist %LocalPath%\lib\avmWinLib.dll (
echo Found Previously Library: 'lib\avmWinLib.dll'
) else (
echo Downloading library: https://%drachost%:%uiport%/software/avctVMWin64.jar
powershell -Command "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(New-Object System.Net.WebClient).DownloadFile('https://%drachost%:%uiport%/software/avctVMWin64.jar', '%LocalPath%\lib\avctVMWin64.jar')"
echo Extracting library: 'lib\avctVMWin64.jar'
Call :unzip "%LocalPath%\lib" "avmWinLib.dll" "%LocalPath%\lib\avctVMWin64.jar" >nul 
)
Call :Check-avmWinLib
EXIT /B 0

:Check-avctKVMIO
echo -----------------------------
echo Checking Integrity: 'lib\avctKVMIO.dll'
FOR /F "usebackq" %%A IN ('%LocalPath%\lib\avctKVMIO.dll') DO set size=%%~zA
if not "%size%"=="206336" (
	echo File Integrity: 'lib\avctKVMIO.dll' has Failed...
	del %LocalPath%\lib\avctKVMIO.dll
	call :Download-avctKVMIO
	call :Check-avctKVMIO
	EXIT /B 0
) else (
echo File Integrity: 'lib\avctKVMIO.dll' has Passed...
)
EXIT /B 0

:Download-avctKVMIO
if exist "%LocalPath%\lib\avctKVMIO.dll" (
	echo Found Previously Library: 'lib\avctKVMIO.dll'
) else  (
echo Downloading library: https://%drachost%:%uiport%/software/avctKVMIOWin64.jar
powershell -Command "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(New-Object System.Net.WebClient).DownloadFile('https://%drachost%:%uiport%/software/avctKVMIOWin64.jar', '%LocalPath%\lib\avctKVMIOWin64.jar')"
echo Extracting library: 'lib\avctKVMIOWin64.jar' 
Call :unzip "%LocalPath%\lib" "avctKVMIO.dll" "%LocalPath%\lib\avctKVMIOWin64.jar" >nul
)
Call :Check-avctKVMIO
EXIT /B 0


:Request-UAC
	setlocal EnableExtensions DisableDelayedExpansion
	call :GetFullBatchFileName FullBatchFileName
	setlocal EnableDelayedExpansion 
	echo Set UAC = CreateObject^("Shell.Application"^) > "getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c cd %cm-d% & ""!FullBatchFileName!"" -d=""%cm-d%"" -h=""%cm-h%"" -k=""%cm-k%"" -w=""%cm-w%"" -u=""%cm-u%"" ", "", "runas", 1 >> "getadmin.vbs"
	endlocal
	endlocal
    "getadmin.vbs"
    del "getadmin.vbs"
    exit /B
	
:GetFullBatchFileName
set "%1=%~f0" & goto :EOF
