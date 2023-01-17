echo "- block: Build & Test Omnibus Packages"
echo "  prompt: Continue to run omnibus package build and tests for applicable platforms?"

omnibus_build_platforms=("centos-6" "centos-7" "centos-8" "rhel-9" "debian-9" "ubuntu-1604" "sles-15")

for platform in ${omnibus_build_platforms[@]}; do
  echo "- label: \":hammer_and_wrench::docker: $platform\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  echo "  timeout_in_minutes: 60"
done

win_omnibus_build_platforms=("windows-2019")

for platform in ${win_omnibus_build_platforms[@]}; do
  echo "- label: \":hammer_and_wrench::windows: $platform\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  echo "        - BUILDKITE_AGENT_ACCESS_TOKEN"
  echo "        - AWS_ACCESS_KEY_ID"
  echo "        - AWS_SECRET_ACCESS_KEY"
  echo "        - AWS_SESSION_TOKEN"
  echo "      volumes:"
  echo '        - "c:\\buildkite-agent:c:\\buildkite-agent"'
  echo "  commands:"
  echo "    - ./.expeditor/scripts/omnibus_chef_build.ps1"
  echo "  timeout_in_minutes: 60"
done

echo "- wait: ~"

omnibus_test_platforms=("amazon-2:centos-7" "centos-6:centos-6" "centos-7:centos-7" "centos-8:centos-8" "rhel-9:rhel-9" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-1604:ubuntu-1604" "ubuntu-1804:ubuntu-1604" "ubuntu-2004:ubuntu-1604" "ubuntu-2204:ubuntu-1604" "sles-15:sles-15")

for platform in ${omnibus_test_platforms[@]}; do
  echo "- env:"
  echo "    OMNIBUS_BUILDER_KEY: build-${platform#*:}"
  echo "  label: \":mag::docker: ${platform%:*}\""
  echo "  retry:"
  echo "    automatic:"
  echo "      limit: 1"
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
  echo "  timeout_in_minutes: 60"
done

echo "- env:"
echo "    OMNIBUS_BUILDER_KEY: build-windows-2019"
echo "  key: test-windows-2019"
echo '  label: ":mag::windows: windows-2019"'
echo "  retry:"
echo "    automatic:"
echo "      limit: 1"
echo "  agents:"
echo "    queue: default-windows-2019-privileged"
echo "  commands:"
echo "    - ./.expeditor/scripts/download_built_omnibus_pkgs.ps1"
echo "    - ./omnibus/omnibus-test.ps1"
echo "  timeout_in_minutes: 60"