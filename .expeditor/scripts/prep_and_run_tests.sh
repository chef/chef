#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]
  then
    echo "No TestType supplied"
fi

TestType=$1

if [ "$TestType" == "Unit" ]
then
    mkdir spec/data/nodes && touch spec/data/nodes/test.rb && touch spec/data/nodes/default.rb && touch spec/data/nodes/test.example.com.rb
fi

echo "--- Update PATH and activate ruby and bundle"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

ruby -v
bundle -v

echo "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3

echo "--- gem info openssl"
gem info openssl
echo "--- system openssl"
openssl version

case $TestType in

    Unit)
        RakeTest=("spec:unit" "component_specs")
        ;;

    Integration)
        RakeTest=("spec:integration")
        ;;

    Functional)
        RakeTest=("spec:functional")
        ;;

    *)
        echo -e "\nTestType $TestType not valid\n" >&2
        exit 1
        ;;
esac

for test in "${RakeTest[@]}"
do
    echo "--- Chef $test run"
    bundle exec rake "$test"
done