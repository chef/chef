#!/bin/bash

# exit immediately on failure, or if an undefined variable is used
set -eu

echo "---"
echo "steps:"
echo ""

test_platforms=("centos-6" "centos-7" "centos-8" "rhel-9" "debian-9" "ubuntu-1604" "sles-15")

for platform in ${test_platforms[@]}; do
  echo "- label: \"{{matrix}} $platform :ruby:\""
  echo "  agents:"
  echo "    queue: default-privileged"
  echo "  matrix:"
  echo "    - \"Unit\""
  echo "    - \"Integration\""
  echo "    - \"Functional\""
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-${platform#*:}:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      privileged: true"
  echo "      environment:"
  echo "        - CHEF_FOUNDATION_VERSION"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh {{matrix}}"
done

win_test_platforms=("windows-2019:windows-2019")

for platform in ${win_test_platforms[@]}; do
  echo "- label: \"{{matrix}} ${platform#*:}\""
  echo "  agents:"
  echo "    queue: default-${platform%:*}-privileged"
  echo "  matrix:"
  echo "    - \"Unit\""
  echo "    - \"Integration\""
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-${platform#*:}:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      shell:"
  echo "      - powershell"
  echo "      - \"-Command\""
  echo "      environment:"
  echo "        - CHEF_FOUNDATION_VERSION"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 {{matrix}}"

done

for platform in ${win_test_platforms[@]}; do
  echo "- label: \"Functional ${platform#*:}\""
  echo "  commands:"
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 Functional"
  echo "  agents:"
  echo "    queue: single-use-windows-2019-privileged"
  echo "  env:"
  echo "  - CHEF_FOUNDATION_VERSION"
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 {{matrix}}"
done

external_gems=("chef-zero" "cheffish" "chefspec" "knife-windows" "berkshelf")

for gem in ${external_gems[@]}; do
  echo "- label: \"$gem gem :ruby:\""
  echo "  agents:"
  echo "    queue: default"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-ubuntu-1804:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      environment:"
  echo "        - CHEF_FOUNDATION_VERSION"
  if [ $gem == "chef-zero" ] 
  then
    echo "        - PEDANT_OPTS=--skip-oc_id"
    echo "        - CHEF_FS=true"
  fi
  echo "      propagate-environment: true"
  echo "  - chef/cache#v1.5.0:"
  echo "      s3_bucket: core-buildkite-cache-chef-oss-prod"
  echo "      cached_folders:"
  echo "      - vendor"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  if [ $gem == "berkshelf" ]
  then
    echo "    - export PATH=\"/opt/chef/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH}\""
    echo "    - apt-get update -y"
    echo "    - apt-get install -y graphviz"
    echo "    - bundle config set --local without omnibus_package"
  else
    echo "    - export PATH=\"/opt/chef/bin:${PATH}\""
    echo "    - bundle config set --local without omnibus_package"
    echo "    - bundle config set --local path 'vendor/bundle'"
  fi
  echo "    - bundle install --jobs=3 --retry=3"
  case $gem in 
    "chef-zero")
      echo "    - bundle exec tasks/bin/run_external_test chef/chef-zero main rake pedant"
      ;;
    "cheffish")
      echo "    - bundle exec tasks/bin/run_external_test chef/cheffish main rake spec"
      ;;
    "chefspec")
      echo "    - bundle exec tasks/bin/run_external_test chefspec/chefspec main rake"
      ;;
    "knife-windows")
      echo "    - bundle exec tasks/bin/run_external_test chef/knife-windows main rake spec"
      ;;
    "berkshelf")
      echo "    - bundle exec tasks/bin/run_external_test chef/berkshelf main rake"
      ;;
    *)
      echo -e "\n Gem $gem is not valid\n" >&2
      exit 1
      ;;
  esac
done

habitat_plans=("linux" "linux-kernel2" "windows")

for plan in ${habitat_plans[@]}; do
  echo "- label: \":habicat: $plan plan\""
  echo "  agents:"
  if [ $plan == "windows" ]
  then
    echo "    queue: single-use-windows-2019-privileged"
  else
    echo "    queue: single-use-privileged"
  fi
  echo "  plugins:"
  echo "  - chef/cache#v1.5.0:"
  echo "      s3_bucket: core-buildkite-cache-chef-oss-prod"
  echo "      cached_folders:"
  echo "      - vendor"
  echo "  commands:"
  if [ $plan == "windows" ]
  then
    echo "    - ./.expeditor/scripts/verify-plan.ps1"
  else
    echo "    - sudo ./.expeditor/scripts/install-hab.sh 'x86_64-$plan'"
    echo "    - sudo ./.expeditor/scripts/verify-plan.sh"
  fi
done

echo "- block: Build & Test Omnibus Packages"
echo "  prompt: Continue to run omnibus package build and tests for applicable platforms?"

omnibus_build_platforms=("centos-6" "centos-7" "centos-8" "rhel-9" "debian-9" "ubuntu-1604" "sles-15")

for platform in ${omnibus_build_platforms[@]}; do
  echo "- label: \":hammer_and_wrench::docker: $platform\""
  echo "  key: build-$platform"
  echo "  agents:"
  echo "    queue: default-privileged"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      privileged: true"
  echo "      propagate-environment: true"
  echo "      environment:"
  echo "        - RPM_SIGNING_KEY"
  echo "        - CHEF_FOUNDATION_VERSION"
  echo "  commands:"
  echo "    - ./.expeditor/scripts/omnibus_chef_build.sh"
done

win_omnibus_build_platforms=("windows-2019")

for platform in ${win_omnibus_build_platforms[@]}; do
  echo "- label: \"Build Omnibus $platform\""
  echo "  key: build-$platform"
  echo "  agents:"
  echo "    queue: default-$platform-privileged"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      shell:"
  echo "      - powershell"
  echo "      - \"-Command\""
  echo "      propagate-environment: true"
  echo "      environment:"
  echo "        - CHEF_FOUNDATION_VERSION"
  echo "  commands:"
  echo "    - ./.expeditor/scripts/omnibus_chef_build.ps1"
done

echo "- wait: ~"

omnibus_test_platforms=("amazon-2:centos-7" "centos-6:centos-6" "centos-7:centos-7" "centos-8:centos-8" "rhel-9:rhel-9" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-1604:ubuntu-1604" "ubuntu-1804:ubuntu-1604" "ubuntu-2004:ubuntu-1604" "ubuntu-2204:ubuntu-1604" "sles-15:sles-15")

for platform in ${omnibus_test_platforms[@]}; do
  echo "- env:"
  echo "    OMNIBUS_BUILDER_KEY: build-${platform#*:}"
  echo "  label: \":mag::docker: ${platform%:*}\""
  echo "  agents:"
  echo "    queue: default-privileged"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: chefes/omnibus-toolchain-${platform%:*}:$OMNIBUS_TOOLCHAIN_VERSION"
  echo "      privileged: true"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - ./.expeditor/scripts/download_built_omnibus_pkgs.sh"
  echo "    - omnibus/omnibus-test.sh"
done
