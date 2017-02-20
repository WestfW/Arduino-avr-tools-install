@echo off
if "%1"=="" (
  :: If we're called without an arg, we're probably going to need to
  :: explicitly reinvoke cmd.exe, which will prevent us from being able
  :: to change the current path.  So use a secondary tmp .bat file
  call :gettempname
) else (
  set TMPFILE=%1
)

if !SystemDrive! NEQ %SystemDrive% (
:: We have to run in /V mode to get late evaluation of variables inside loops
  cmd.exe /V /C %0 %TMPFILE%
  call %TMPFILE%
  @echo Checking tool versions
  @echo. 
  avr-gcc --version
  avrdude -v
  goto :eof
)
:: Look for avr-gcc in path.
@echo Looking for avr-gcc in current path
:: @set ERRORLEVEL=0
@where avr-gcc >NUL 2>NUL
IF %ERRORLEVEL% EQU 0 (
  @ECHO avr-gcc already installed
  where avr-gcc
  avr-gcc --version
  exit /b 1
) ELSE (
  @ECHO No avr-gcc currently installed.
)
:: look for Arduino install.
IF EXIST "%ProgramFiles%\Arduino*" (
  @echo Found at least one Arduino Program
  FOR /F "tokens=*" %%f IN ('dir /b /x "%ProgramFiles%\Arduino*"') DO (
    SET prg=%ProgramFiles%\%%f
    @echo Looks like !prg! has version:
    call :gccversion "!prg!\Hardware\tools\avr\bin\avr-gcc.exe"
    SET /P confirm="Use !prg! ? [y/n]>"
::    @ echo got response: !confirm!
    if "!confirm!"=="y" (
::      echo selected prg = !prg!
      GOTO gotdir
    )
  )
  GOTO noarduino
) ELSE (
:noarduino
  @echo Can't find Arduino prg=%prg%
  exit /b 1
)
  
:: prompt for arduino install location.
@echo asking if this is OK
SET /P confirm="Use %prg% [y/n]>"
if "%confirm%" NEQ "y" exit /b 0

:gotdir

:: figure out arduino install version.
:: @echo gotdir has prg = %prg%
IF EXIST "%prg%\hardware\tools\avr\bin\avr-gcc.exe" (
::  @echo Looks like 1.6+ Install.
  @echo Found avr-gcc !
  set bin=%prg%\hardware\tools\avr\bin
  for %%i in ("%prg%\hardware\tools\avr\etc") do (
::    @echo looping
    set etc=%%~sfi
  )
) else (
  @echo Can't find a bin directory
  exit /b 1
)
:: find bin directory.
:: create tentative path for binaries.
:: check tool versions.
@echo Setting paths to include bin and etc
:: setx PATH "%PATH%;%bin%;%etc%"
:: PATH %PATH%;%bin%;%etc%
echo PATH %PATH%;%bin%;%etc%>%TMPFILE%
goto :eof

:gccversion
:: This implements "gcc --version | head -1" - show the first line
if EXIST %1 (
  FOR /F "delims=*" %%l in ('%1 --version') DO (
    @echo %%l
    :: return after we've output one line
    exit /b 0
  )
)
exit /b 0

:gettempname
set TMPFILE=%TMP%\mytempfile-%RANDOM%-%TIME:~6,5%.bat
if exist "%TMPFILE%" GOTO GETTEMPNAME
:: goto :eof

