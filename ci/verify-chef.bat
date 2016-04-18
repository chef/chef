
@ECHO OFF

REM ; %PROJECT_NAME% is set by Jenkins, this allows us to use the same script to verify
REM ; Chef and Angry Chef
cd C:\opscode\%PROJECT_NAME%\bin

REM ; We don't want to add the embedded bin dir to the main PATH as this
REM ; could mask issues in our binstub shebangs.
SET EMBEDDED_BIN_DIR=C:\opscode\%PROJECT_NAME%\embedded\bin

ECHO.

REM ; Set the temporary directory to a custom location, and wipe it before
REM ; and after the tests run.
SET TEMP=%TEMP%\cheftest
SET TMP=%TMP%\cheftest
RMDIR /S /Q %TEMP%
MKDIR %TEMP%

FOR %%b IN (
  chef-client
  knife
  chef-solo
  ohai
) DO (


  ECHO Checking for existence of binfile `%%b`...

  IF EXIST %%b (
    ECHO ...FOUND IT!
  ) ELSE (
    GOTO :error
  )
  ECHO.
)

call chef-client --version

REM ; Exercise various packaged tools to validate binstub shebangs
call %EMBEDDED_BIN_DIR%\ruby --version
call %EMBEDDED_BIN_DIR%\gem --version
call %EMBEDDED_BIN_DIR%\bundle --version
call %EMBEDDED_BIN_DIR%\rspec --version

SET PATH=C:\opscode\%PROJECT_NAME%\bin;C:\opscode\%PROJECT_NAME%\embedded\bin;%PATH%

REM ; Test against the vendored chef gem (cd into the output of "bundle show chef")
for /f "delims=" %%a in ('bundle show chef') do cd %%a

IF NOT EXIST "Gemfile.lock" (
  ECHO "Chef gem does not contain a Gemfile.lock! This is needed to run any tests."
  GOTO :error
)

IF "%PIPELINE_NAME%" == "chef-fips" (
  set CHEF_FIPS=1
)

REM ; ffi-yajl must run in c-extension mode for perf, so force it so we don't accidentally fall back to ffi
set FORCE_FFI_YAJL=ext

set BUNDLE_GEMFILE=C:\opscode\%PROJECT_NAME%\Gemfile
set BUNDLE_IGNORE_CONFIG=true
set BUNDLE_FROZEN=1
call bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o %WORKSPACE%\test.xml -f documentation spec/functional
