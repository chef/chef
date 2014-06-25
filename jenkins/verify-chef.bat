
@ECHO OFF

REM ; %PROJECT_NAME% is set by Jenkins, this allows us to use the same script to verify
REM ; Chef and Angry Chef
cd C:\opscode\%PROJECT_NAME%\bin

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

chef-client --version
