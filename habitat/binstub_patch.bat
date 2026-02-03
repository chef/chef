@ECHO OFF

REM skip this if hab pkg exec has already done it, APPBUNDLER_ALLOW_RVM will be set if hab pkg exec
IF NOT DEFINED APPBUNDLER_ALLOW_RVM (
  REM Get the drive letter of the current batch file
  SET "BINSTUB_DRIVE=%~d0"

  REM Prepend vendor path to PATH if it exists (using full path with drive)
  IF EXIST "%~dp0..\vendor" (
    SET "PATH=%~dp0..\vendor;%PATH%"
  )

  IF EXIST "%~dp0..\RUNTIME_ENVIRONMENT" (
    REM Process each line from RUNTIME_ENVIRONMENT
    FOR /F "usebackq tokens=1* delims==" %%A IN ("%~dp0..\RUNTIME_ENVIRONMENT") DO (
      REM Skip comments (lines starting with #)
      SET "varname=%%A"
      SET "firstchar=%%A"
      SET "firstchar=!firstchar:~0,1!"
      IF NOT "!firstchar!"=="#" (
        SET "varvalue=%%B"
        IF NOT "!varvalue!"=="" (
          REM Check if this is PATH
          IF /I "%%A"=="PATH" (
            REM Process PATH value - add drive letter to paths starting with backslash
            CALL :ProcessPath "%%B"
          ) ELSE (
            REM For other variables, add drive letter if starts with backslash
            SET "testchar=%%B"
            SET "testchar=!testchar:~0,1!"
            IF "!testchar!"=="\" (
              SET "%%A=%BINSTUB_DRIVE%%%B"
            ) ELSE (
              SET "%%A=%%B"
            )
          )
        )
      )
    )
  )

  SET "APPBUNDLER_ALLOW_RVM=true"
)

REM Continue to the rest of the script (this file is patched into other batch files)
GOTO :SkipBinstubFunctions

:ProcessPath
SET "origpath=%~1"
SET "newpath="
:pathloop
FOR /F "tokens=1* delims=;" %%X IN ("%origpath%") DO (
  SET "segment=%%X"
  SET "testchar=%%X"
  SET "testchar=!testchar:~0,1!"
  IF "!testchar!"=="\" (
    SET "segment=%BINSTUB_DRIVE%%%X"
  )
  IF "%newpath%"=="" (
    SET "newpath=!segment!"
  ) ELSE (
    SET "newpath=!newpath!;!segment!"
  )
  SET "origpath=%%Y"
  IF NOT "%%Y"=="" GOTO pathloop
)
SET "PATH=%newpath%;%PATH%"
GOTO :EOF

:SkipBinstubFunctions
REM Binstub functions defined above, continue with the rest of the script
