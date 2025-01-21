#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]
  then
    echo "No TestType supplied"
fi

TestType=$1

# we load chef-foundation here to get some of the basic tools we need for testing and installing gems with
# curl -fsSL https://omnitruck.chef.io/chef/install.sh | bash -s -- -c "current" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"

gem install bundler --no-document -v 2.3.7

export PATH="/opt/chef/bin:${PATH}"

if [ "$TestType" == "Unit" ]
then
    mkdir spec/data/nodes && touch spec/data/nodes/test.rb && touch spec/data/nodes/default.rb && touch spec/data/nodes/test.example.com.rb
fi

echo "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3 

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