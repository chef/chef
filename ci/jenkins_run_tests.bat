set PATH=C:\Ruby192\bin;%PATH%

REM Chef 10 contains the client in the chef/ sub-directory
cd chef

ruby -v
call bundle install --binstubs --path vendor/bundle || ( call rm Gemfile.lock && call bundle install --binstubs --path vendor/bundle )
ruby bin\rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec/functional spec/unit
