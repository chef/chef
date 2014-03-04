ruby -v

call bundle check

if %ERRORLEVEL% NEQ 0 (
   call rm Gemfile.lock
   call bundle install --without docgen --path vendor/bundle
)

bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec/functional spec/unit spec/stress spec/integration

set RSPEC_ERRORLVL=%ERRORLEVEL%
REM Return the error level from rspec
exit /B %RSPEC_ERRORLVL%
