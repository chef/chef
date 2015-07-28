
@ECHO OFF

REM ; %PROJECT_NAME% is set by Jenkins, this allows us to use the same script to verify
REM ; Chef and Angry Chef
cd C:\opscode\%PROJECT_NAME%\bin

REM ; We don't want to add the embedded bin dir to the main PATH as this
REM ; could mask issues in our binstub shebangs.
SET EMBEDDED_BIN_DIR=C:\opscode\%PROJECT_NAME%\embedded\bin

ECHO(

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
  ECHO(
)

call chef-client --version

REM ; Exercise various packaged tools to validate binstub shebangs
call %EMBEDDED_BIN_DIR%\ruby --version
call %EMBEDDED_BIN_DIR%\gem --version
call %EMBEDDED_BIN_DIR%\bundle --version
call %EMBEDDED_BIN_DIR%\rspec --version

SET PATH=C:\opscode\%PROJECT_NAME%\bin;C:\opscode\%PROJECT_NAME%\embedded\bin;%PATH%

REM ; Test against the appbundle'd Chef
cd c:\opscode\%PROJECT_NAME%\embedded\apps\chef
call bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o %WORKSPACE%\test.xml -f documentation spec/unit
