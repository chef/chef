#!/bin/bash

# exit immediately on failure, or if an undefined variable is used
set -eu

cat << SCRIPT | sed -r 's/^ {2}//'
  ---
  steps:

SCRIPT

test_platforms=("centos-6" "centos-7" "centos-8" "rhel-9" "debian-9" "ubuntu-1604" "sles-15")

for platform in ${test_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: "{{matrix}} $platform :ruby:"
    retry:
      automatic:
        limit: 1
    agents:
      queue: default-privileged
    matrix:
      - "Unit"
      - "Integration"
      - "Functional"
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-${platform#*:}:$OMNIBUS_TOOLCHAIN_VERSION
        privileged: true
        environment:
          - CHEF_FOUNDATION_VERSION
        propagate-environment: true
    commands:
      - .expeditor/scripts/prep_and_run_tests.sh {{matrix}}
    timeout_in_minutes: 60
SCRIPT
done

win_test_platforms=("windows-2019:windows-2019")

for platform in ${win_test_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: "{{matrix}} ${platform#*:} :windows:"
    retry:
      automatic:
        limit: 1
    agents:
      queue: default-${platform%:*}-privileged
    matrix:
      - "Unit"
      - "Integration"
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-${platform#*:}:$OMNIBUS_TOOLCHAIN_VERSION
        shell:
        - powershell
        - "-Command"
        environment:
          - CHEF_FOUNDATION_VERSION
        propagate-environment: true
    commands:
      - .\.expeditor\scripts\prep_and_run_tests.ps1 {{matrix}}
    timeout_in_minutes: 60
SCRIPT
done

for platform in ${win_test_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: "Functional ${platform#*:} :windows:"
    retry:
      automatic:
        limit: 1
    commands:
      - .\.expeditor\scripts\prep_and_run_tests.ps1 Functional
    agents:
      queue: single-use-windows-2019-privileged
    env:
    - CHEF_FOUNDATION_VERSION
      - .\.expeditor\scripts\prep_and_run_tests.ps1 {{matrix}}
    timeout_in_minutes: 60
SCRIPT
done

external_gems=("chef-zero" "cheffish" "chefspec" "knife-windows" "berkshelf")

for gem in ${external_gems[@]}; do
  # If Gem is Chef-Zero
  if [ $gem == "chef-zero" ]
  then
    chef_zero_envs=$(cat <<-SCRIPT

          - PEDANT_OPTS=--skip-oc_id
          - CHEF_FS=true
SCRIPT
)
  else
    chef_zero_envs=''
  fi

  # If Gem is Berkshelf
  if [ $gem == "berkshelf" ]
  then
    gem_commands=$(cat <<-SCRIPT

      - export PATH="/opt/chef/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH}"
      - apt-get update -y
      - apt-get install -y graphviz
      - bundle config set --local without omnibus_package
SCRIPT
)
  else
    gem_commands=$(cat <<-SCRIPT

      - export PATH="/opt/chef/bin:${PATH}"
      - bundle config set --local without omnibus_package
      - bundle config set --local path 'vendor/bundle'
SCRIPT
)
  fi

  # Configure correct bundle exec per Gem
  case $gem in 
    "chef-zero")
      exec_command="- bundle exec tasks/bin/run_external_test chef/chef-zero main rake pedant"
      ;;
    "cheffish")
      exec_command="- bundle exec tasks/bin/run_external_test chef/cheffish main rake spec"
      ;;
    "chefspec")
      exec_command="- bundle exec tasks/bin/run_external_test chefspec/chefspec main rake"
      ;;
    "knife-windows")
      exec_command="- bundle exec tasks/bin/run_external_test chef/knife-windows main rake spec"
      ;;
    "berkshelf")
      exec_command="- bundle exec tasks/bin/run_external_test chef/berkshelf main rake"
      ;;
    *)
      echo -e "\n Gem $gem is not valid\n" >&2
      exit 1
      ;;
  esac

  # The entire YAML entry
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: "$gem gem :ruby:"
    retry:
      automatic:
        limit: 1
    agents:
      queue: default
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-ubuntu-1804:$OMNIBUS_TOOLCHAIN_VERSION
        environment:
          - CHEF_FOUNDATION_VERSION$chef_zero_envs
        propagate-environment: true
    - chef/cache#v1.5.0:
        s3_bucket: core-buildkite-cache-chef-oss-prod
        cached_folders:
        - vendor
    commands:
      - .expeditor/scripts/bk_container_prep.sh$gem_commands
      - bundle install --jobs=3 --retry=3
      $exec_command
    timeout_in_minutes: 60
SCRIPT
done

habitat_plans=("linux" "linux-kernel2" "windows")

for plan in ${habitat_plans[@]}; do
  # Use correct agent
  if [ $plan == "windows" ]
  then
    verify_agent="single-use-windows-2019-privileged"
  else
    verify_agent="single-use-privileged"
  fi

  # Use correct verify script(s)
  if [ $plan == "windows" ]
  then
    verify_script=$(cat <<-SCRIPT

      - ./.expeditor/scripts/verify-plan.ps1
SCRIPT
)
  else
    verify_script=$(cat <<-SCRIPT

      - sudo ./.expeditor/scripts/install-hab.sh 'x86_64-$plan'
      - sudo ./.expeditor/scripts/verify-plan.sh
SCRIPT
)
  fi

  # The entire YAML entry
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: ":habicat: $plan plan"
    retry:
      automatic:
        limit: 1
    agents:
      queue: $verify_agent
    plugins:
    - chef/cache#v1.5.0:
        s3_bucket: core-buildkite-cache-chef-oss-prod
        cached_folders:
        - vendor
    commands:$verify_script
    timeout_in_minutes: 60
SCRIPT
done

# include build and test omnibus pipeline
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/build-test-omnibus.sh"