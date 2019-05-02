
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

REM ; FIXME: we should really use Bundler.with_clean_env in the caller instead of re-inventing it here
set _ORIGINAL_GEM_PATH=
set BUNDLE_BIN_PATH=
set BUNDLE_GEMFILE=
set GEM_HOME=
set GEM_PATH=
set GEM_ROOT=
set RUBYLIB=
set RUBYOPT=
set RUBY_ENGINE=
set RUBY_ROOT=
set RUBY_VERSION=
set BUNDLER_VERSION=

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

REM ; Test against the vendored chef gem (cd into the output of "gem which chef")
for /f "delims=" %%a in ('gem which chef') do set CHEFDIR=%%a
call :dirname "%CHEFDIR%" CHEFDIR
call :dirname "%CHEFDIR%" CHEFDIR
cd %CHEFDIR%

cd

IF "%PIPELINE_NAME%" == "chef-fips" (
  set CHEF_FIPS=1
)

REM ; ffi-yajl must run in c-extension mode for perf, so force it so we don't accidentally fall back to ffi
set FORCE_FFI_YAJL=ext

call %EMBEDDED_BIN_DIR%\bundle install
call %EMBEDDED_BIN_DIR%\bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o %WORKSPACE%\test.xml -f documentation spec/functional

GOTO :EOF

:dirname file varName
    setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _dir=%~dp1
    SET _dir=%_dir:~0,-1%
    endlocal & set %2=%_dir%
GOTO thout:EOF
