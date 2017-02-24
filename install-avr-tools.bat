@echo off
@echo.
SET DEBUG=REM
call :clearerrors
%DEBUG% checking args.  errorlevel=%ERRORLEVEL%
set TMPFILE=%1
if "%1" EQU "" (
  REM If we're called without an arg, we're probably going to need to
  REM explicitly reinvoke cmd.exe, which will prevent us from being able
  REM to change the current path.  So use a secondary tmp .bat file
  call :gettemp
)

REM See if we're already in Delayed Evaluation mode.
%DEBUG% checking cmd mode
if "!x!" NEQ "%x%" (
  REM We have to run in /V mode to get late evaluation of variables inside loops
  %DEBUG% re-running in delayed eval mode
  cmd.exe /V /C "%0" %TMPFILE%
  %DEBUG% recursion finished.  Errorlevel %ERRORLEVEL%
  if ERRORLEVEL 1 ( GOTO EOF )
  REM Assuming it worked, invoke the temp file that was created
  if not exist %TMPFILE% (
    %DEBUG% Unexpected error.  No TMPFILE %TMPFILE%
    exit /b 432
  )
  %DEBUG% calling tmpfile
  call %TMPFILE%
  REM Pretty print some stuff for the user. 
  @echo Checking tool versions
  @echo. 
  avr-gcc --version
  avrdude -v
  REM And we're done (Most of the work being done in the sub-process.)
  goto eof
)

REM ======================================================================

REM Here is most of the work of the script.
REM Look through the various places where an Arduino install is likely to exist,
REM  make sure that we can find the avr-gcc binaries that should be part of that
REM  install, print out the version, and ask the user if that's what they want.

REM Look for existing avr-gcc in path.
%DEBUG% Looking for avr-gcc in current path
call :clearerrors
call :which avr-gcc.exe
IF "%gotwhich%" NEQ "" (
  @ECHO avr-gcc already installed at %gotwhich%
  avr-gcc --version
  exit /b 123
) ELSE (
  @ECHO No avr-gcc currently installed.
)
REM look for Arduino install.
IF EXIST "%ProgramFiles%\Arduino*" (
  @echo Found at least one Arduino Program
  @echo.
  FOR /F "tokens=*" %%f IN ('dir /b /x "%ProgramFiles%\Arduino*"') DO (
    SET prg=%ProgramFiles%\%%f
    @echo Looks like !prg! has version 
    call :gccversion "!prg!\Hardware\tools\avr\bin\avr-gcc.exe"
    SET /P confirm="Use !prg! ? [y/n]>"
    if "!confirm!"=="y" (
      SET aroot=!prg!
      GOTO gotdir
    )
  )
  REM try some of the more unlikely places that Arduino might live.
  goto :noarduino
) ELSE (
:noarduino
  @echo Can't find Arduino
  exit /b 5678
)
  
REM prompt for arduino install location.
@echo ****WHY DID WE GET HERE****
@echo asking if this is OK
SET /P confirm="Use %prg% [y/n]>"
if "%confirm%" NEQ "y" exit /b 0


:gotdir
REM figure out arduino install version.
%DEBUG% gotdir has prg = %prg%
IF EXIST "%prg%\hardware\tools\avr\bin\avr-gcc.exe" (
  @echo Found avr-gcc
  set bin=%prg%\hardware\tools\avr\bin
  set etc=%prg%\hardware\tools\avr\etc
) else (
  @echo Cant find a bin directory
  exit /b 963
)

%DEBUG% Checking for utils at %prg%\hardware\tools\avr\utils\bin\
IF EXIST "%aroot%\hardware\tools\avr\utils\bin\make.exe" (
  REM See if we have make and etc as well (from Arduino 1.0.x/WinAVR)
  %DEBUG% Found make.exe
  set utils=%aroot%\hardware\tools\avr\utils\bin
)


REM find bin directory.
REM create tentative path for binaries and put it in our tmp batch file
%DEBUG% Setting paths to include bin and etc
REM setx PATH "%PATH%;%bin%;%etc%"
REM PATH %PATH%;%bin%;%etc%
echo PATH %PATH%;%bin%;%etc%>%TMPFILE%
if "%utils%" NEQ "" (
   REM Check for make already installed
   %DEBUG% Have utils; checking whether make is already installed.
   call :which make.exe
   if "%gotwhich%" EQU "" (
      %DEBUG Adding utils as well at %utils%
      echo PATH %PATH%;%bin%;%etc%;%utils%>%TMPFILE%

   )
)

exit /b 0
goto eof


REM ----------------------------------------------------------------------
REM          Subroutines
REM ----------------------------------------------------------------------

:which
    %DEBUG% which %1
    SET gotwhich=
    for %%i in (%1) do set fullspec=%%~$PATH:i
    if not "x!fullspec!"=="x" (
       %DEBUG% !fullspec!
       set gotwhich=!fullspec!    
    )
    %DEBUG% End which %gotwhich%
    goto eof


:gccversion
   REM This implements "gcc --version | head -1" - show the first line
   if EXIST %1 (
     FOR /F "delims=*" %%l in ('%1 --version') DO (
       @echo %%l
       REM return after we've output one line
       exit /b 0
     )
   )
   exit /b 0

REM ----------------------------------------------------------------------

REM Get a unique temporary filename,
REM   Thus uses our scriptname, a random number, and the time
:gettemp
   set TMPFILE=%TMP%\install-avr-tools-%RANDOM%-%TIME:~6,5%.bat
   if exist "%TMPFILE%" GOTO gettempname
   exit /b 0

REM ----------------------------------------------------------------------

REM Clear the ERRORLEVEL to 0, if it happened to be set
:clearerrors
   exit /b 0

:eof
