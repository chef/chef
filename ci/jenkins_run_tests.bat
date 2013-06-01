set PATH=C:\Ruby192\bin;%PATH%

ruby -v
call bundle install --binstubs --without docgen --path vendor/bundle || ( call rm Gemfile.lock && call bundle install --binstubs --path vendor/bundle )
ruby bin\rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec/functional spec/unit spec/stress
set RSPEC_ERRORLVL=%ERRORLEVEL%

REM Return the error level from rspec
exit /B %RSPEC_ERRORLVL%
