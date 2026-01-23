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
