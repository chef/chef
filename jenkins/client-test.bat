SETLOCAL

rem # remove the chef package / clobber the files
rem # then install the new package
rmdir /S /Q C:\opscode
FOR %%i IN (pkg\chef*.msi) DO SET omnibus_package=%%i
call msiexec INSTALLLOCATION=C:\opscode /qb /i %omnibus_package% || GOTO :error

rem # extract the chef source code
mkdir src\chef
FOR %%i IN (src\chef*.tar.gz) DO SET omnibus_source_tarball=%%i
call C:\opscode\chef\bin\tar.exe xvzf %omnibus_source_tarball% -C src\chef || GOTO :error

rem # COMPAT HACK - Chef 11 finally has the core Chef code in the root of the
rem # project repo. Since the Chef Client pipeline needs to build/test Chef 10.x
rem # and 11 releases our test script need to handle both cases gracefully.
IF EXIST .\src\chef\chef (
  cd .\src\chef\chef
) ELSE (
  cd .\src\chef
)

rem # install all of the development gems
mkdir .\bundle
set PATH=C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;%PATH%
call bundle install --without server --path bundle || GOTO :error

rem # run the tests
call bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o %WORKSPACE%\test.xml -f documentation spec || GOTO :error

GOTO :EOF

:error
ECHO Failed with error level %errorlevel%

ENDLOCAL