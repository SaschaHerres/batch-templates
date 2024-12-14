@:force_elevation_when_needed__v3
@REM this one-liner enforces admin privileges (elevation), when needed
@REM documentation & updates: https://github.com/SaschaHerres/batch-templates
@REM ---------------------------------------------------------------------------
@REM # this code is best put in the first line(s) of a script, then:
@REM   # if this script is already running in an elevated context: do nothing
@REM     (skip to next line and thus the rest of the script)
@REM   # if not elevated: ask for elevation (admin credentials), then re-run
@REM     this script in a new window while retaining the working directory and
@REM     all command line arguments, wait for elevated instance to end and catch
@REM     the exit code, then end this script itself and return that exit code
@REM     (providing full transparency to outside cmds/scripts/environments)
@REM   # on any errors during internal processing (including the user pressing
@REM     'cancel' on elevation dialog) exit this script and return code '1000'
@REM     (so the rest of the script is never executed in a non-elevated context)
@REM ---------------------------------------------------------------------------
@REM details of operation (in order of usage):
@REM * in general: use of '&' to concatenate commands regardless of their result
@REM * '@' hide command display and show only output for this line ('echo off')
@REM * 'SETLOCAL ENABLEDELAYEDEXPANSION' starts localisation and delayed
@REM   expansion of environment variables; the first prevents this code to
@REM   manipulate variables later used in this script; the second is needed,
@REM   because all further code is in one line, but some variables are needed to
@REM   be evaluated at execution time (instead of the time, the line is parsed);
@REM   important: 'ENDLOCAL' has to be set, whenever this code block is left
@REM * 3x 'SET "...=..."' to define path to native executable used by this code
@REM   * fully qualified path without variables except '%SystemRoot%'
@REM   * on assignment of the variable, by putting the leading '"' in front of
@REM     the variable name, the path can contain spaces but will not have the
@REM     surrounding '"'; on later use, the variable has to be surrounded by '"'
@REM   * further in this code, only the variable names will be used, in contrast
@REM     to this documentation, where the short executable names are used:
@REM     * '!net_exe!' -> 'net.exe'
@REM     * '!pws_exe!' -> 'powershell.exe'
@REM     * '!cmd_exe!' -> 'cmd.exe'
@REM * '(FOR ...)' ensures, that rest of line is only processed after for loop:
@REM   * loops through native executables (defined above):
@REM     * 'IF NOT EXIST "%%~f"' checks, if file is not present in file system
@REM       * then safely ends script, outputting/returning '1001' and pausing
@REM         (this fatal error should never happen)
@REM * use 'net.exe FILE' as native command, that reliably fails, when run
@REM   non-elevated; following '>NUL 2>&1' hides all output/errors (redirection)
@REM * 'IF NOT ERRORLEVEL 1 (...)' runs brackets, if previous command succeeded:
@REM   * 'ENDLOCAL' restores all variable values and the 'delayed expansion' to
@REM     the state before the last 'SETLOCAL' (which is the start if this line)
@REM   * nothing else, so skip to next line here and thus the rest of the script
@REM * 'ELSE ...' runs rest of line, on previous command fail (elevation needed)
@REM * handle escaping of all '"' within command line arguments, store in
@REM   variable '!args!' to safely run the new instance later:
@REM   * use surrounding '^"' to safely assign string with unknown number of '"'
@REM   * to prevent errors, skip further string manipulation on empty arguments
@REM   * special case (bug?): when '%*' has odd number of '"', the closing '^'
@REM     is catched into variable value; so check for and remove a trailing '^'
@REM     -> there is no regular case, where '%*' could end with a '^'
@REM   * finally escape all '"' as '\"\"' (see below for rules on escaping)
@REM   * the surrounding brackets in both '(IF ...)' statements ensure, that
@REM     code behind the closing bracket is run in either case
@REM * use of 'powershell.exe -Command "&{ ... }"' as surrounding shell to run
@REM   multiple powershell commands via a script block:
@REM   * this is needed, because getting the exit code from a command run by
@REM     'powershell.exe' requires an additional command ('exit')
@REM   * '-NoProfile' ignores a possible user profile with conflicting settings
@REM   * '-ExecutionPolicy Bypass' ignores (when possible) all restrictions,
@REM     warnings and prompts
@REM   * from here on, PowerShell demands embedded '"' to be escaped as '\"'
@REM   * use 'Start-Process' CmdLet as second surrounding shell for elevation:
@REM     * '$p=Start-Process -Wait -PassThru' to wait for child process to end,
@REM       retrieve the exit code and assign it to the variable '$p'
@REM     * '-ErrorAction Stop' will break execution at any kind of error (see
@REM       error handling below)
@REM     * '-Verb RunAs' for native elevation prompt
@REM     * '-FilePath is used to run the 'cmd.exe' process as third surrounding
@REM       shell and supply '-ArgumentList' as parameter string; both are
@REM       surrounded by escaped '"', because they are part of the powershell
@REM       script block (see above):
@REM       * because 'cmd.exe' needs embedded '"' to be escaped as '""' and the
@REM         escaping rules of powershell also apply (see above), all further
@REM         '"' within 'ArgumentList' must be double escaped to '\"\"', so that
@REM         PowerShell can dequote any '\"' to '"' and then 'cmd.exe' can
@REM         dequote '""' to '"'
@REM       * 'ArgumentList' starts with '/C' instructing 'cmd.exe' to run the
@REM         following string and then terminate returning the (last) exit code;
@REM         because the first character after '/S ' is a '"', 'cmd.exe' will
@REM         strip the leading and last '"' on the remaining command line
@REM         (which is limited by the 'ArgumentList' string)
@REM       * the remaining string consists of two commands concatenated by an
@REM         escaped '&':
@REM         * 'CHDIR /D "%CD% "' switches to the current working directory,
@REM           meaning the one, that was set right before running this line of
@REM           code (that is, where the '%CD%' variable is evaluated); the
@REM           trailing ' ' after '%CD%' is needed, when '%CD%' is a drive's
@REM           root folder, where %CD% ends with '\', which will interfere with
@REM           the following '\"' and break PowerShell's command-line parsing
@REM         * '"%~f0"' is the current script's fully qualified path (stripped
@REM           of possibly surrounding quotes, than surrounded by quotes to
@REM           allow spaces/special characters) followed by '!args!' variable,
@REM           that contains all preprocessed command line arguments (see above)
@REM   * ';' ends the first and starts the next command within the script block
@REM     * 'if ($Error.Count -eq 0) {exit $p.ExitCode} else {exit 1000}' does
@REM       the error handling for the previous PowerShell command:
@REM       * when no errors occured, end the 'powershell.exe' shell returning
@REM         the exit code from 'Start-Process' stored in '$p'
@REM       * when error(s) occured, end returning '1000'
@REM       * -> use of '$Error.Count' is safe here (fresh PowerShell session)
@REM * '>NUL 2>&1' as follow-up to the initial call of 'powershell.exe' hides
@REM   all output/errors (redirection)
@REM * 'ENDLOCAL' restores all variable values and the 'delayed expansion' to
@REM   the state before the last 'SETLOCAL' (which is the start if this line)
@REM * 'EXIT /B !ERRORLEVEL!' ends this script returning the last exit code
@REM   ('ENDLOCAL' does not alter it), which is the one from 'powershell.exe'
@REM ---------------------------------------------------------------------------
@REM remarks using this code:
@REM - for command line arguments there is no further testing/escaping of any
@REM   possibly unsafe characters (e.g.: '^','|','&','<','>','%'); when using
@REM   quoted strings, there should be no problem, but fancy escaping might
@REM   break it; e.g. the following works <x>.cmd "1^|" "2<2 2>2" 3 "4&o|u^r_^""
@REM   -> on parse errors, 'powershell.exe' will likely fail with exit code 255
@REM - when the elevated instance lacks access to either the script's path or
@REM   '%CD%', this code will fail (e.g. run from a user's profile, where admin
@REM   account has no read permission); but that is beyond scope of this code
@REM - when ending a script containing this code, a conditional 'PAUSE' might be
@REM   useful for the case, that a new window with the elevated instance had
@REM   been opened; otherwise that window closes and all screen output is gone;
@REM   to accomplish that, use the following line at the very end of the script:
@REM   (ECHO "%CMDCMDLINE:"=%" | FIND /I "%~f0" >NUL 2>&1) && (ECHO. & PAUSE)
@REM   - works for multiple scripts calling each other, where each has this code
@REM     (only those opening a new window will do the final pause)
@REM   - works also for scripts run via double click
@REM - when using my code, I would like to ask you to keep at least the first 3
@REM   lines starting with the label (':force_elevation_...') ahead of it -- :)
@REM ---------------------------------------------------------------------------
@REM achieved design goals:
@REM ~ use of only native executables and commands, that are present in a fresh
@REM   install of Windows, no need to install additional features, no inclusion
@REM   of external libraries or sources
@REM ~ code is adapted to fit in on line to ease copying it into other scripts
@REM   (downside is bad readability and partly different code vs a multiline
@REM   writedown, especially the brackets)
@REM ~ full transparency vs outside cmds/scripts/environments: proper transfer
@REM   of command line arguments to the elevated instance
@REM ~ full transparency vs rest of the script: no changes to variables,
@REM   internal settings or command line arguments and no use of functions or
@REM   labels, that all could break the rest of the script
@REM ~ error handling and reporting via exit code (especially for the elevation)
@REM ----------------------------------------------------------------------------
@SETLOCAL ENABLEDELAYEDEXPANSION & SET "net_exe=%SystemRoot%\System32\net.exe" & SET "pws_exe=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" & SET "cmd_exe=%SystemRoot%\system32\cmd.exe" & (FOR %%f IN ("!net_exe!","!pws_exe!","!cmd_exe!") DO (IF NOT EXIST "%%~f" ECHO FATAL ERROR 1000 ^("%%~f"^) & ENDLOCAL & EXIT /B 1000)) & "!net_exe!" FILE >NUL 2>&1 & IF NOT ERRORLEVEL 1 (ENDLOCAL) ELSE SET ^"args=%*^" & (IF DEFINED args (IF [!args:~-1!]==[^^] SET ^"args=!args:~0,-1!^") & SET ^"args=!args:"=\"\"!^") & "!pws_exe!" -NoProfile -ExecutionPolicy Bypass -Command "&{ $p=Start-Process -Wait -PassThru -ErrorAction Stop -Verb RunAs -FilePath \"!cmd_exe!\" -ArgumentList \"/C \"\"CHDIR /D \"\"%CD% \"\"^&\"\"%~f0\"\" !args!\"\"\"; if ($Error.Count -eq 0) {exit $p.ExitCode} else {exit 1000} }" >NUL 2>&1 & ENDLOCAL & EXIT /B !ERRORLEVEL!
