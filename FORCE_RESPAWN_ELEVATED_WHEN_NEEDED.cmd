:FORCE_RESPAWN_ELEVATED_WHEN_NEEDED_V3.0
REM this one-liner enforces admin privileges (elevation), when needed; for documentation see: https://github.com/SaschaHerres/batch-templates
REM # if this script is already running in an elevated context: do nothing but skip to next line
REM # if not elevated: ask for elevation, spawn new instance of this script in a new window while keeping working directory and all command line arguments, wait for
REM   instance to exit, then exit itself while returning the catched exit code; this provides 100% transparency to a cmd/script, where this script has been called from
REM details:
REM * 'DELAYEDEXPANSION' must be enabled before, except for that put this code at the top most line of your script
REM * 'net FILE' as native command, that reliably fails when run non-elevated
REM * safe escaping of '"' in command line arguments for spawning new instance; note: usage of surrounding '^"' to assign variable with odd/unknown numbers of '"';
REM   special case: when '%*' has odd number of '"', the closing '^' is catched in the variable, so check & remove that; note, there is no case, where '%*' ends with '^'
REM * 'powershell.exe -Command' as surrounding shell to handle new instance and a second command ('exit') for passing through the ERRORLEVEL to originating script
REM * PowerShell's 'Start-Process' with '-Verb RunAs' for native elevation prompt, '-Wait' and '-PassThru' for recieving the ERRORLEVEL
REM * '%ComSpec%' as shell to ensure proper quoting of script file name (so path may contain spaces/special characters) and original arguments (see above for quoting)
REM * preceeding 'CHDIR' to run instance in same working directory; note: trailing ' ' after '%CD%' to avoid error when run from a drive's root (where %CD% ends with '\')
REM additional notes:
REM - this code is adapted to fit in on line to ease reusing in multiple scripts; for a multiline layout some adaptions might not be needed
REM - when elevated context has no access to script's location, the code fails (e.g. run from user profile, where admin has no read access), but this is beyond this code
REM - for security reasons native executables are run via their well-known fully qualified path names, where only '%SystemRoot%' is trusted but no other paths/variables
REM - except for the safe escaping of '"' in command line arguments, there is no input validation or escaping for non-quoted arguments (e.g. for: ^ | & < > or %);
REM   test case: the following arguments will safely be handled and passed to the new instance: <x>.cmd "1^|" "2<2 2>2" 3 "4&o|u^r_^""
REM - at the regular exit of this script, a 'PAUSE' might be useful in case a new window has been opened, otherwise the window auto closes and all output is gone;
REM   to accomplish that for an elevated new instance by this code (and also for originating scripts run via double click), use the following line at the end:
REM   ECHO "%CMDCMDLINE:"=%" | FIND /I "%~f0" >NUL 2>&1 & IF NOT ERRORLEVEL 1 ECHO. & PAUSE
"%SystemRoot%\System32\net.exe" FILE >NUL 2>&1 & IF ERRORLEVEL 1 SET ^"args=%*^" & (IF DEFINED args (IF [!args:~-1!]==[^^] SET ^"args=!args:~0,-1!^") & SET ^"args=!args:"=\"\"!^") & "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& {$p=Start-Process -Wait -PassThru -Verb RunAs -FilePath "%SystemRoot%\system32\cmd.exe" -ArgumentList \"/C \"\"CHDIR /D \"\"%CD% \"\"^&\"\"%~f0\"\" !args!\"\"\"; Exit $p.ExitCode;}" >NUL 2>&1 & ENDLOCAL & EXIT /B !ERRORLEVEL!
