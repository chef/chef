SETLOCAL

ECHO %OMNIBUS_PROJECT_NAME%

if "%OMNIBUS_PROJECT_NAME%"=="" (
  ECHO "OMNIBUS_PROJECT_NAME environment variable is not set!"
  EXIT /B 1
)

IF "%CLEAN%"=="true" (
  rmdir /Q /S c:\opscode
  rmdir /Q /S c:\omnibus-ruby
  rmdir /Q /S .\pkg
)

set PATH=C:\Ruby193\bin;%PATH%
set SSL_CERT_FILE=C:\Ruby193\ssl\certs\cacert.pem

call bundle install --without development || GOTO :error

IF "%RELEASE_BUILD%"=="true" (

  call bundle exec omnibus build %OMNIBUS_PROJECT_NAME% -l internal --override append_timestamp:false || GOTO :error

) ELSE (

  call bundle exec omnibus build %OMNIBUS_PROJECT_NAME% -l internal || GOTO :error

)

GOTO :EOF

:error
ECHO Failed with error level %errorlevel%

ENDLOCAL
