SETLOCAL

ECHO %OMNIBUS_PROJECT_NAME%

if "%OMNIBUS_PROJECT_NAME%"=="" (
  ECHO "OMNIBUS_PROJECT_NAME environment variable is not set!"
  EXIT /B 1
)

rem # IF NOT EXIST jenkins\chef-solo\cache mkdir jenkins\chef-solo\cache

IF "%CLEAN%"=="true" (
  rmdir /Q /S c:\opscode
  rmdir /Q /S c:\omnibus-ruby
  rmdir /Q /S .\pkg
)

call bundle install || GOTO :error

rem # ensure berkshelf is installed
where /q berks
IF NOT %ERRORLEVEL% == 0 (
  call gem install berkshelf --no-ri --no-rdoc
)

rem # install omnibus cookbook and dependencies
call berks install --path=vendor/cookbooks

call chef-solo -c .\jenkins\solo.rb -j .\jenkins\dna-windows.json -l debug || GOTO :error

call copy /Y omnibus.rb.example.windows omnibus.rb || GOTO :error

rem # we're guaranteed to have the correct ruby installed into C:\Ruby193 from chef-solo cookbooks
rem # bundle install from here now too
set PATH=C:\Ruby193\bin;%PATH%
rem # ensure the installed certificate authority is loaded
set SSL_CERT_FILE=C:\Ruby193\ssl\certs\cacert.pem
call bundle install || GOTO :error

call bundle exec omnibus build project %OMNIBUS_PROJECT_NAME%-windows || GOTO :error

GOTO :EOF

:error
ECHO Failed with error level %errorlevel%

ENDLOCAL
