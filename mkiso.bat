@echo off
rem This script will take as input a directory contianing other files and
rem folders and create a CD image that can be burned to CD using any CD writing
rem software. This script requires the cygwin environment with mkisofs
rem installed.

rem Set up cygwin environment.
set CYGWIN_ROOT=c:\cygwin
set PATH=.;%CYGWIN_ROOT%\bin;%PATH%
set CYGPATH=%CYGWIN_ROOT%\bin\cygpath.exe
set BASH=%CYGWIN_ROOT%\bin\bash.exe

if not exist "%CYGWIN_ROOT%" goto nocygwin
if not exist "%CYGPATH%" goto nocygpath
if not exist "%BASH%" goto nobash
if not exist "%CYGWIN_ROOT%\bin\mkisofs" goto nomkisofs

rem Get the input directory stripping any surrounding quotes and converting it
rem to a fully qualified path name.
set indir=%~f1

if not exist "%indir%" goto usage

rem Convert single slashes to double slashes so they don't get stripped.
set indir=%indir:\=\\%

rem Convert the windows path to Cygwin path.

rem I'd really like to be able to do this:
rem
rem 	set cygdir=`c:\cygwin\bin\cygpath -pu "%indir%"`
rem
rem but Windows doesn't have an equivalent for that. I can use this:
rem
rem 	for /F "tokens=*" %%t in ('c:\cygwin\bin\cygpath -pu "%indir%"') do set cygdir=%%t
rem
rem except this doesn't work on paths with spaces. It tokenizes the input in
rem parenthesis on spaces and the for loop iterates over the resutling list so
rem cygdir contains only the last token. Instead I can try this:
rem
rem 	for /F "tokens=*" %%t in ('c:\cygwin\bin\cygpath -pu "%indir%"') do set cygdir=%cygdir% %%t
rem
rem to rebuild the path from the tokens, however, the variable is expanded when
rem the line is read, not executed. It is expanded too early and cygdir still
rem ends up with only the last token.
rem
rem Delayed expansion is disabled by default so I need to turn that on here.
rem This will allow the use of the ! character to indicate delayed expansion so
rem the variable is expanded each time the statement is executed instead of
rem only once when it is read.
rem
rem Stupid Windows...
setlocal enabledelayedexpansion

set cygdir=
for /F "tokens=*" %%t in ('%CYGPATH% -pu "%indir%"') do set cygdir=!cygdir! %%t

rem Chomp leading space tacked on by above FOR statement.
set cygdir=%cygdir:~1%

rem Create the iso file using the input directory name.
if exist "%~1.iso" goto overwrite

:doit
%BASH% -c "mkisofs -R -J -o \"%cygdir%.iso\" \"%cygdir%\""
goto done

:overwrite
set /p c=WARNING: %~1.iso already exists, overwrite? (Y/N) 
if %c%==y goto doit
goto out

:usage
echo USAGE: mkiso ^<input directory^>
goto out

:nocygwin
echo ERROR: cannot find Cygwin installation!
goto out

:nocygpath
echo ERROR: cannot find cygpath!
goto out

:nobash
echo ERROR: cannot find bash!
goto out

:nomkisofs
echo ERROR: cannot find mkisofs!
goto out

:done
pause
:out
