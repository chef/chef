SETLOCAL

rem # copy off the timestamp for fingerprinting before we blow it away later
move %BUILD_NUMBER%\build_timestamp %WORKSPACE%\

rem # run the tests
cd %BUILD_NUMBER%

rem # remove the chef package / clobber the files
rem # then install the new package
rmdir /S /Q C:\opscode
FOR %%i IN (pkg\chef*.msi) DO SET omnibus_package=%%i
SET omnibus_package=%WORKSPACE%\%BUILD_NUMBER%\%omnibus_package%

call copy /Y "%omnibus_package%" %TMP%\install.msi || GOTO :error

call msiexec INSTALLLOCATION=C:\opscode /qb /i %TMP%\install.msi || GOTO :error

rem # use rspec and gems from omnibus
set PATH=C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;%PATH%

rem # run against the specs that are packaged in the chef gem
rem # sorry about the chef-20 bug on the line below, but this really needs to be rewritten in powershell before then...
cd c:\opscode\chef\embedded\lib\ruby\gems\1.9.1\gems\chef-1*

rem # run the tests -- exclude spec/stress on windows
rem # we do not bundle exec here in order to test against the gems in the omnibus package
call rspec -r rspec_junit_formatter -f RspecJunitFormatter -o %WORKSPACE%\test.xml -f documentation spec/functional spec/unit || GOTO :error

rem # check presence of essential binaries in correct places

cd c:\opscode\chef\bin

IF NOT EXIST chef-client GOTO :error
IF NOT EXIST chef-solo GOTO :error
IF NOT EXIST knife GOTO :error
IF NOT EXIST ohai GOTO :error

rem # uninstall chef
call msiexec /qb /x %TMP%\install.msi || GOTO :error

rem # clean up the workspace to save disk space
cd %WORKSPACE%
rmdir /S /Q %BUILD_NUMBER%

GOTO :EOF

:error

SET ERR_LEV=%errorlevel%

ECHO Failed with error level %ERR_LEV%

rem # uninstall chef
call msiexec /qb /x %TMP%\install.msi

EXIT /B %ERR_LEV%

ENDLOCAL
