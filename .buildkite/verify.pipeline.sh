#!/bin/bash
# exit immediately on failure, or if an undefined variable is used
set -eu

# If the only changed files are under .github/, skip all tests
BASE_BRANCH="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-main}"
changed_files=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || true)

if [[ -n "$changed_files" ]] && ! echo "$changed_files" | grep -qv '^\.github/'; then
  echo "steps: []"
  exit 0
fi

echo "---"
echo "env:"
echo "  BUILD_TIMESTAMP: $(date +%Y-%m-%d_%H-%M-%S)"
echo "  CHEF_LICENSE_SERVER: http://hosted-license-service-lb-8000-606952349.us-west-2.elb.amazonaws.com:8000/"
echo "steps:"
echo ""
# RHEL-family platforms (RHEL 9): run Unit, Functional, and Integration in Buildkite (requires subscription).
# Rocky: run Integration only here; Unit/Functional run in GitHub Actions (unit-docker, functional-docker).
# Debian: run Integration only here; Unit/Functional run in GitHub Actions (unit-docker, functional-docker).
# Ubuntu: run Integration only here; Unit/Functional run in GitHub Actions.
# Windows: run Integration only here; Unit/Functional run in GitHub Actions.

rhel_platforms=("rhel-9" "rhel-9-aarch64")
rocky_platforms=("rocky-8" "rocky-8-aarch64" "rocky-9" "rocky-9-aarch64")
debian_platforms=("debian-11" "debian-11-aarch64")
ubuntu_platforms=("ubuntu-2204" "ubuntu-2204-aarch64")

for platform in ${rhel_platforms[@]}; do

  if [[ $platform == *"-aarch64" ]]; then
    image="chefes/omnibus-toolchain-${platform%-aarch64}:aarch64"
    queue="default-privileged-aarch64"
  else
    image="chefes/omnibus-toolchain-${platform}:$OMNIBUS_TOOLCHAIN_VERSION"
    queue="default-privileged"
  fi

  echo "- label: \"{{matrix}} $platform :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: $queue"
  echo "  matrix:"
  echo "    - \"Unit\""
  echo "    - \"Integration\""
  echo "    - \"Functional\""
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: $image"
  echo "      privileged: true"
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh {{matrix}}"
  echo "  timeout_in_minutes: 60"
done

for platform in ${rocky_platforms[@]}; do

  if [[ $platform == *"-aarch64" ]]; then
    image="chefes/omnibus-toolchain-${platform%-aarch64}:aarch64"
    queue="default-privileged-aarch64"
  else
    image="chefes/omnibus-toolchain-${platform}:$OMNIBUS_TOOLCHAIN_VERSION"
    queue="default-privileged"
  fi

  echo "- label: \"Integration $platform :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: $queue"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: $image"
  echo "      privileged: true"
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh Integration"
  echo "  timeout_in_minutes: 60"
done

for platform in ${debian_platforms[@]}; do

  if [[ $platform == *"-aarch64" ]]; then
    image="chefes/omnibus-toolchain-${platform%-aarch64}:aarch64"
    queue="default-privileged-aarch64"
  else
    image="chefes/omnibus-toolchain-${platform}:$OMNIBUS_TOOLCHAIN_VERSION"
    queue="default-privileged"
  fi

  echo "- label: \"Integration $platform :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: $queue"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: $image"
  echo "      privileged: true"
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh Integration"
  echo "  timeout_in_minutes: 60"
done

for platform in ${ubuntu_platforms[@]}; do

  if [[ $platform == *"-aarch64" ]]; then
    image="chefes/omnibus-toolchain-${platform%-aarch64}:aarch64"
    queue="default-privileged-aarch64"
  else
    image="chefes/omnibus-toolchain-${platform}:$OMNIBUS_TOOLCHAIN_VERSION"
    queue="default-privileged"
  fi

  echo "- label: \"Integration $platform :ruby:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: $queue"
  echo "  plugins:"
  echo "  - docker#v3.5.0:"
  echo "      image: $image"
  echo "      privileged: true"
  echo "      environment:"
  echo "        - HAB_AUTH_TOKEN"
  echo "      propagate-environment: true"
  echo "  commands:"
  echo "    - .expeditor/scripts/bk_container_prep.sh"
  echo "    - .expeditor/scripts/prep_and_run_tests.sh Integration"
  echo "  timeout_in_minutes: 60"
done
win_test_platforms=("windows-2019:windows-2019")
for platform in ${win_test_platforms[@]}; do
  echo "- label: \"Integration ${platform#*:} :windows:\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
  echo "  agents:"
  echo "    queue: default-${platform%:*}-privileged"
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
  echo "    - .\.expeditor\scripts\prep_and_run_tests.ps1 Integration"
  echo "  timeout_in_minutes: 120"
done

# External gem tests (chef-zero, cheffish, chefspec, knife-windows, berkshelf)
# have been migrated to GitHub Actions: .github/workflows/gem_tests.yml
habitat_plans=("x86_64-linux" "aarch64-linux" "windows")
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
    if [[ $plan == "aarch64-"* ]]; then
      echo "    queue: default-privileged-aarch64"
    else
      echo "    queue: default-privileged"
    fi
    echo "  plugins:"
    echo "  - docker#v3.5.0:"
    if [[ $plan == "aarch64-"* ]]; then
      echo "      image: chefes/omnibus-toolchain-ubuntu-2204:aarch64"
    else
      echo "      image: chefes/omnibus-toolchain-ubuntu-2204:$OMNIBUS_TOOLCHAIN_VERSION"
    fi
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
    echo "    - sudo -E ./.expeditor/scripts/install-hab.sh $plan"
    echo "    - sudo -E ./.expeditor/scripts/verify-plan.sh"
  fi
done
