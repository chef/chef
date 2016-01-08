
@ECHO OFF

cd C:\opscode\chefdk\bin

ECHO(

FOR %%b IN (
  berks
  chef
  chef-client
  kitchen
  knife
  rubocop
) DO (


  ECHO Checking for existence of binfile `%%b`...

  IF EXIST %%b (

    ECHO ...FOUND IT!

  ) ELSE (

    GOTO :error

  )
  ECHO(
)

chef verify
