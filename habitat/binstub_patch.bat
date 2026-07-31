REM skip this if hab pkg exec has already done it, APPBUNDLER_ALLOW_RVM will be set if hab pkg exec
IF NOT DEFINED APPBUNDLER_ALLOW_RVM (
  SET "APPBUNDLER_ALLOW_RVM=true"
  REM Set up GEM_PATH: chef-cli gem dir
  SET "RUBY_GEM_VERSION=3.4.0"
  SET "CHEF_CLI_GEM_DIR=%USERPROFILE%\.chef\ruby\%RUBY_GEM_VERSION%\gems"
  IF DEFINED GEM_PATH (
    SET "GEM_PATH=%CHEF_CLI_GEM_DIR%;%GEM_PATH%"
  ) ELSE (
    SET "GEM_PATH=%CHEF_CLI_GEM_DIR%"
  )
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
