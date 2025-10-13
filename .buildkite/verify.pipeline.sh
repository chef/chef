#!/bin/bash

# exit immediately on failure, or if an undefined variable is used
set -eu

echo "---"
echo "env:"
echo "  BUILD_TIMESTAMP: $(date +%Y-%m-%d_%H-%M-%S)"
echo "  CHEF_LICENSE_SERVER: http://hosted-license-service-lb-8000-606952349.us-west-2.elb.amazonaws.com:8000/"
echo "steps:"
echo ""

test_platforms=("rocky-8" "rocky-9" "rhel-9" "debian-9" "ubuntu-2004")

for platform in ${test_platforms[@]}; do
  echo "- label: \"{{matrix}} $platform :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh {{matrix}}"
  echo "  timeout_in_minutes: 60"
done

win_test_platforms=("windows-2019:windows-2019")

for platform in ${win_test_platforms[@]}; do
  echo "- label: \"{{matrix}} ${platform#*:} :windows:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 {{matrix}}"
  echo "  timeout_in_minutes: 120"
done

for platform in ${win_test_platforms[@]}; do
  echo "- label: \"Functional ${platform#*:} :windows:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: single-use-windows-2019-privileged"
  echo "  matrix:"
  echo "    - \"Functional\""
  echo "  commands:"
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 Functional"
  echo "  timeout_in_minutes: 120"
done

external_gems=("chef-zero" "cheffish" "chefspec" "knife-windows" "berkshelf")

for gem in ${external_gems[@]}; do
  echo "- label: \"$gem gem :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  # echo "  - chef/cache#v1.5.0:"
  # echo "      s3_bucket: core-buildkite-cache-chef-oss-prod"
  # echo "      cached_folders:"
  # echo "      - vendor"
  echo "  timeout_in_minutes: 60"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  if [ $gem == "berkshelf" ]
  then
    echo "    - export PATH=\"/root/.rbenv/shims:/opt/chef/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH}\""
    echo "    - apt-get update -y"
    # cspell:disable-next-line
    echo "    - apt-get install -y graphviz"
    echo "    - bundle config set --local without omnibus_package"
  else
    echo "    - export PATH=\"/root/.rbenv/shims:/opt/chef/bin:${PATH}\""
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
      echo "    - bundle exec tasks/bin/run_external_test chef/chefspec main rake"
      ;;
    "knife-windows")
      echo "    - bundle exec tasks/bin/run_external_test chef/knife-windows main rake spec"
      ;;
    "berkshelf")
      echo "    - bundle exec tasks/bin/run_external_test chef/berkshelf 61c6c77e4aea00ed6be0af64c6f7260226cc1bdd rake" # temporary pin to get past verify
      ;;
    *)
      echo -e "\n Gem $gem is not valid\n" >&2
      exit 1
      ;;
  esac
done

habitat_plans=("linux" "windows")

for plan in ${habitat_plans[@]}; do
  echo "- label: \":habicat: $plan plan\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  if [ $plan == "windows" ]
  then
    echo "    queue: single-use-windows-2019-privileged"
  else
    echo "    queue: single-use-privileged"
  fi
  # echo "  plugins:"
  # echo "  - chef/cache#v1.5.0:"
  # echo "      s3_bucket: core-buildkite-cache-chef-oss-prod"
  # echo "      cached_folders:"
  # echo "      - vendor"
  echo "  env:"
  echo "    ARTIFACTORY_URL: ${ARTIFACTORY_URL:-https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local}"
  echo "    ARTIFACTORY_TOKEN: ${ARTIFACTORY_TOKEN:-}"
  echo "  timeout_in_minutes: 60"
  echo "  commands:"
  if [ $plan == "windows" ]
  then
    echo "    - \$env:HAB_STUDIO_SECRET_ARTIFACTORY_TOKEN=\$env:ARTIFACTORY_TOKEN"
    echo "    - ./.expeditor/scripts/verify-plan.ps1"
  else
    echo "    - sudo -E ./.expeditor/scripts/install-hab.sh 'x86_64-$plan'"
    echo "    - sudo --preserve-env=HAB_STUDIO_SECRET_ARTIFACTORY_TOKEN,ARTIFACTORY_TOKEN env HAB_STUDIO_SECRET_ARTIFACTORY_TOKEN=\$ARTIFACTORY_TOKEN ./.expeditor/scripts/verify-plan.sh"
  fi
done
