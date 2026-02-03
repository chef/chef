REM skip this if hab pkg exec has already done it, APPBUNDLER_ALLOW_RVM will be set if hab pkg exec
IF NOT DEFINED APPBUNDLER_ALLOW_RVM (
  REM Get the drive letter of the current batch file
  SET "BINSTUB_DRIVE=%~d0"

  REM Prepend vendor path to PATH if it exists
  IF EXIST "%~dp0..\vendor" (
    SET "PATH=%BINSTUB_DRIVE%%~p0..\vendor;%PATH%"
  )

  IF EXIST "%~dp0..\RUNTIME_ENVIRONMENT" (
    FOR /F "usebackq tokens=* delims=" %%A IN ("%~dp0..\RUNTIME_ENVIRONMENT") DO (
      SET "line=%%A"
      REM Skip empty lines and comments
      IF NOT "!line!"=="" (
        IF NOT "!line:~0,1!"=="#" (
          REM Check if this is a PATH variable assignment
          SET "var=%%A"
          IF "!var:~0,5!"=="PATH=" (
            REM Extract the PATH value and prepend drive letter
            SET "pathval=!var:~5!"
            SET "PATH=%BINSTUB_DRIVE%!pathval!;%PATH%"
          ) ELSE (
            REM For other variables, prepend drive letter if it's a path-like value
            SET "%%A"
          )
        )
      )
    )
  )
)
