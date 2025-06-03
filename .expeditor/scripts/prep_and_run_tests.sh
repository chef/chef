#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]
  then
    echo "No TestType supplied"
fi

TestType=$1

curl -fsSL https://omnitruck.chef.io/chef/install.sh | bash -s -- -c "stable" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"
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
