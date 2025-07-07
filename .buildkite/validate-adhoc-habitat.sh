set -e pipefail

targets=("amazon-2:centos-7" "centos-7:centos-7" "rhel-9:rhel-9" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-2004:ubuntu-2004" "ubuntu-2204:ubuntu-2204" "rocky-8:rocky-8" "rocky-9:rocky-9" "amazon-2023:amazon-2023" "windows-2016:windows-2019" "windows-2022:windows-2019" "windows-10:windows-2019" "windows-11:windows-2019")

arm_targets=("centos-7-arm:centos-7-arm" "amazon-2-arm:amazon-2-arm" "rhel-9-arm:rhel-9-arm" "ubuntu-1804-arm:ubuntu-1804-arm" "ubuntu-2004-arm:ubuntu-2004-arm" "ubuntu-2204-arm:ubuntu-2204-arm" "amazon-2023-arm:amazon-2023-arm")

if [ -n "${ARM_ENABLED:-}" ] && [ "${ARM_ENABLED:-}" = "1" ]; then
  targets+=("${arm_targets[@]}")
fi

# Pull the latest chef/chef-infra-client package identifier from habitat
# This will ensure that we test and promote the right package version
# even if we have a new version in the unstable channel.
echo "- label: \":habicat: Fetching latest package identifier.\""
echo "  commands:"
echo "    - sudo -E ./.expeditor/scripts/buildkite_adhoc_metadata.sh"
echo "  expeditor:"
echo "    executor:"
echo "      linux:"
echo "        privileged: true"
echo "        single-use: true"

echo "- wait: ~"

for target in ${targets[@]}; do
  if [[ "${target%:*}" == *"windows"* ]]; then
    echo "- label: :hammer_and_wrench::windows:${target%:*}"
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    echo "  agents:"
    echo "    queue: default-${target%:*}-privileged"
    echo "  plugins:"
    echo "    - docker#v3.5.0:"
    echo "        image: chefes/omnibus-toolchain-${target%:*}:$OMNIBUS_TOOLCHAIN_VERSION"
    echo "        shell:"
    echo "          - powershell"
    echo "          - \"-Command\""
    echo "        propagate-environment: true"
    echo "  commands:"
    echo "    - sudo -E ./.expeditor/scripts/validate_adhoc_build.ps1"
    echo "  timeout_in_minutes: 120"
  else
    echo "- label: :hammer_and_wrench::docker:${target%:*}"
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    echo "  agents:"
    if [[ "${target%:*}" == *"arm"* ]]; then
      echo "    queue: docker-linux-arm64"
    else
      echo "    queue: default-privileged"
    fi
    echo "  plugins:"
    echo "    - docker#v3.5.0:"
    echo "        image: chefes/omnibus-toolchain-${target%:*}:$OMNIBUS_TOOLCHAIN_VERSION"
    echo "        privileged: true"
    echo "        propagate-environment: true"
    echo "  commands:"
    if [[ "${target%:*}" == *"arm"* ]]; then
      echo "    - sudo -E ./.expeditor/scripts/install-hab.sh <arm>"
    else
      echo "    - sudo -E ./.expeditor/scripts/install-hab.sh x86_64-linux"
    fi
    echo "    - sudo -E ./.expeditor/scripts/validate_adhoc_build.sh"
    echo "  timeout_in_minutes: 120"
  fi
done

# if [[ "$BUILDKITE_BRANCH" == "$BUILDKITE_PIPELINE_DEFAULT_BRANCH" ]]; then
#   echo "- wait"
#   echo "- label: \":habicat: Promoting packages to the current channel.\""
#   echo "  commands:"
#   echo "    - export PKG_IDENT=$(buildkite-agent meta-data get \"INFRA_HAB_PKG_IDENT\")"
#   echo "    - hab pkg promote \$PKG_IDENT current x86_64-linux"
#   echo "    - hab pkg promote \$PKG_IDENT current x86_64-windows"
#   echo "  expeditor:"
#   echo "    executor:"
#   echo "      docker:"
#   echo "        - HAB_AUTH_TOKEN"
# fi
