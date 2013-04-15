SETLOCAL

:loop
IF "%1"=="" GOTO :continue
IF "%1"=="-p" (
  SET omnibus_project=%2
  SHIFT
)
SHIFT
GOTO :loop
:continue

if "%omnibus_project%"=="" (
  ECHO Usage: build [-p PROJECT_NAME]
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

call chef-solo -c .\jenkins\solo.rb -j .\jenkins\windows-dna.json -l debug || GOTO :error

call copy /Y omnibus.rb.example.windows omnibus.rb || GOTO :error

rem # we're guaranteed to have the correct ruby installed into C:\Ruby193 from chef-solo cookbooks
rem # bundle install from here now too
set PATH=C:\Ruby193\bin;%PATH%
call bundle install || GOTO :error

call bundle exec omnibus build project %omnibus_project%-windows || GOTO :error

GOTO :EOF

:error
ECHO Failed with error level %errorlevel%

ENDLOCAL

