cat << SCRIPT | sed -r 's/^ {2}//'
  - block: Build & Test Omnibus Packages"
    prompt: Continue to run omnibus package build and tests for applicable platforms?"
SCRIPT

omnibus_build_platforms=("centos-6" "centos-7" "centos-8" "rhel-9" "debian-9" "ubuntu-1604" "sles-15")

for platform in ${omnibus_build_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: ":hammer_and_wrench::docker: $platform"
    retry:
      automatic:
        limit: 1
    key: build-$platform
    agents:
      queue: default-privileged
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION
        privileged: true
        propagate-environment: true
        environment:
          - RPM_SIGNING_KEY
          - CHEF_FOUNDATION_VERSION
    commands:
      - ./.expeditor/scripts/omnibus_chef_build.sh
    timeout_in_minutes: 60
SCRIPT
done

win_omnibus_build_platforms=("windows-2019")

for platform in ${win_omnibus_build_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - label: ":hammer_and_wrench::windows: $platform"
    retry:
      automatic:
        limit: 1
    key: build-$platform
    agents:
      queue: default-$platform-privileged
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION
        shell:
        - powershell
        - "-Command"
        propagate-environment: true
        environment:
          - CHEF_FOUNDATION_VERSION
          - BUILDKITE_AGENT_ACCESS_TOKEN
          - AWS_ACCESS_KEY_ID
          - AWS_SECRET_ACCESS_KEY
          - AWS_SESSION_TOKEN
        volumes:
          - "c:\\\\buildkite-agent:c:\\\\buildkite-agent"
    commands:
      - ./.expeditor/scripts/omnibus_chef_build.ps1
    timeout_in_minutes: 60
SCRIPT
done

echo "- wait: ~"

omnibus_test_platforms=("amazon-2:centos-7" "centos-6:centos-6" "centos-7:centos-7" "centos-8:centos-8" "rhel-9:rhel-9" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-1604:ubuntu-1604" "ubuntu-1804:ubuntu-1604" "ubuntu-2004:ubuntu-1604" "ubuntu-2204:ubuntu-1604" "sles-15:sles-15")

for platform in ${omnibus_test_platforms[@]}; do
  cat << SCRIPT | sed -r 's/^ {2}//'
  - env:
      OMNIBUS_BUILDER_KEY: build-${platform#*:}
    label: ":mag::docker: ${platform%:*}"
    retry:
      automatic:
        limit: 1
    agents:
      queue: default-privileged
    plugins:
    - docker#v3.5.0:
        image: chefes/omnibus-toolchain-${platform%:*}:$OMNIBUS_TOOLCHAIN_VERSION
        privileged: true
        propagate-environment: true
    commands:
      - ./.expeditor/scripts/download_built_omnibus_pkgs.sh
      - omnibus/omnibus-test.sh
    timeout_in_minutes: 60
SCRIPT
done

cat << SCRIPT
- env:
    OMNIBUS_BUILDER_KEY: build-windows-2019
  key: test-windows-2019
  label: ":mag::windows: windows-2019"
  retry:
    automatic:
      limit: 1
  agents:
    queue: default-windows-2019-privileged
  commands:
    - ./.expeditor/scripts/download_built_omnibus_pkgs.ps1
    - ./omnibus/omnibus-test.ps1
  timeout_in_minutes: 60
SCRIPT
