#!/bin/bash
# exit immediately on failure, or if an undefined variable is used
set -eu
echo "---"
echo "env:"
echo "  BUILD_TIMESTAMP: $(date +%Y-%m-%d_%H-%M-%S)"
echo "  CHEF_LICENSE_SERVER: http://hosted-license-service-lb-8000-606952349.us-west-2.elb.amazonaws.com:8000/"
echo "steps:"
echo ""
test_platforms=("rocky-8" "rocky-9" "rhel-9" "debian-11" "ubuntu-2204")
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
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
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
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
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
  echo "    queue: default-windows-2019-privileged"
  echo "  matrix:"
  echo "    - \"Functional\""
  echo "  env:"
  echo "    - HAB_AUTH_TOKEN"
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
  echo "        - HAB_AUTH_TOKEN"
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
      echo "    - bundle exec tasks/bin/run_external_test chef/berkshelf main rake"
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
    echo "    queue: default-windows-2019-privileged"
    echo "  plugins:"
    echo "  - docker#v3.5.0:"
    echo "      image: chefes/omnibus-toolchain-windows-2019:$OMNIBUS_TOOLCHAIN_VERSION"
    echo "      shell:"
    echo "      - powershell"
    echo "      - \"-Command\""
    echo "      environment:"
    echo "        - HAB_AUTH_TOKEN"
    echo "        - BUILDKITE_ORGANIZATION_SLUG"
    echo "      propagate-environment: true"
  else
    echo "    queue: default-privileged"
    echo "  plugins:"
    echo "  - docker#v3.5.0:"
    echo "      image: chefes/omnibus-toolchain-ubuntu-1804:$OMNIBUS_TOOLCHAIN_VERSION"
    echo "      privileged: true"
    echo "      environment:"
    echo "        - HAB_AUTH_TOKEN"
    echo "        - BUILDKITE_ORGANIZATION_SLUG"
    echo "      propagate-environment: true"
  fi
  # echo "  plugins:"
  # echo "  - chef/cache#v1.5.0:"
  # echo "      s3_bucket: core-buildkite-cache-chef-oss-prod"
  # echo "      cached_folders:"
  # echo "      - vendor"
  echo "  timeout_in_minutes: 120"
  echo "  commands:"
  if [ $plan == "windows" ]
  then
    echo "    - ./.expeditor/scripts/verify-plan.ps1"
  else
    echo "    - sudo -E ./.expeditor/scripts/install-hab.sh 'x86_64-$plan'"
    echo "    - sudo -E ./.expeditor/scripts/verify-plan.sh"
  fi
done
