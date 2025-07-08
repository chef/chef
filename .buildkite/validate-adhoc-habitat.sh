#!/bin/bash
set -euo pipefail

targets=("amazon-2:centos-7" "centos-7:centos-7" "rhel-9:rhel-9" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-2004:ubuntu-2004" "ubuntu-2204:ubuntu-2204" "rocky-8:rocky-8" "rocky-9:rocky-9" "amazon-2023:amazon-2023" "windows-2016:windows-2019" "windows-2022:windows-2019" "windows-10:windows-2019" "windows-11:windows-2019")
arm_targets=("centos-7-arm:centos-7-arm" "amazon-2-arm:amazon-2-arm" "rhel-9-arm:rhel-9-arm" "ubuntu-1804-arm:ubuntu-1804-arm" "ubuntu-2004-arm:ubuntu-2004-arm" "ubuntu-2204-arm:ubuntu-2204-arm" "amazon-2023-arm:amazon-2023-arm")

if [ -n "${ARM_ENABLED:-}" ] && [ "${ARM_ENABLED:-}" = "1" ]; then
  targets+=("${arm_targets[@]}")
fi

# Fetching latest package identifier step
echo "- label: \":habicat: Fetching latest package identifier.\""
echo "  commands:"
echo "    - sudo ./.expeditor/scripts/install-hab.sh x86_64-linux"
echo "    - sudo hab pkg install chef/chef-infra-client --channel unstable"
echo "    - export PKG_IDENT=\$(hab pkg path chef/chef-infra-client | grep -oP 'chef/chef-infra-client/[0-9]+\.[0-9]+\.[0-9]+')"
echo "    - buildkite-agent meta-data set \"INFRA_HAB_PKG_IDENT\" \$PKG_IDENT"
echo "  expeditor:"
echo "    executor:"
echo "      linux:"
echo "        privileged: true"
echo "        single-use: true"

# Wait step
echo "- wait: ~"

# Generate steps for each target
for target in "${targets[@]}"; do
  build_platform="${target%%:*}"
  if [[ "${build_platform}" == *"windows"* ]]; then
    echo "- label: :hammer_and_wrench::windows:${build_platform}"
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    echo "  agents:"
    echo "    queue: default-${build_platform}-privileged"
    echo "  plugins:"
    echo "    - docker#v3.5.0:"
    echo "        image: chefes/omnibus-toolchain-${build_platform}:\$OMNIBUS_TOOLCHAIN_VERSION"
    echo "        shell:"
    echo "          - powershell"
    echo "          - \"-Command\""
    echo "        propagate-environment: true"
    echo "  commands:"
    echo "    - \$env:PKG_IDENT = \$(buildkite-agent meta-data get \"INFRA_HAB_PKG_IDENT\")"
    echo "    - ./.expeditor/scripts/validate_adhoc_build.ps1 \$env:PKG_IDENT"
    echo "  timeout_in_minutes: 120"
  else
    echo "- label: :hammer_and_wrench::docker:${build_platform}"
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    echo "  agents:"
    if [[ "${build_platform}" == *"arm"* ]]; then
      echo "    queue: docker-linux-arm64"
    else
      echo "    queue: default-privileged"
    fi
    echo "  plugins:"
    echo "    - docker#v3.5.0:"
    echo "        image: chefes/omnibus-toolchain-${build_platform}:\$OMNIBUS_TOOLCHAIN_VERSION"
    echo "        privileged: true"
    echo "        propagate-environment: true"
    echo "  commands:"
    if [[ "${build_platform}" == *"arm"* ]]; then
      echo "    - sudo ./.expeditor/scripts/install-hab.sh <arm>"
    else
      echo "    - sudo ./.expeditor/scripts/install-hab.sh x86_64-linux"
    fi
    echo "    - export PKG_IDENT=\$(buildkite-agent meta-data get \"INFRA_HAB_PKG_IDENT\")"
    echo "    - sudo ./.expeditor/scripts/validate_adhoc_build.sh \$PKG_IDENT"
    echo "  timeout_in_minutes: 120"
  fi
done
