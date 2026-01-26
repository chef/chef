REM skip this if hab pkg exec has already done it, APPBUNDLER_ALLOW_RVM will be set if hab pkg exec
IF NOT DEFINED APPBUNDLER_ALLOW_RVM (
  IF EXIST "%~dp0..\RUNTIME_ENVIRONMENT" (
    FOR /F "usebackq tokens=* delims=" %%A IN ("%~dp0..\RUNTIME_ENVIRONMENT") DO (
      SET "line=%%A"
      REM Skip empty lines and comments
      IF NOT "!line!"=="" (
        IF NOT "!line:~0,1!"=="#" (
          SET "%%A"
        )
      )
    )
  )
)
