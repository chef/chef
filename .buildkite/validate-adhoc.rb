#!/usr/bin/env ruby

require 'yaml'
require 'time'

targets = [
  "amazon-2:centos-7",
  "centos-7:centos-7",
  "rhel-9:rhel-9",
  "debian-9:debian-9",
  "debian-10:debian-9",
  "debian-11:debian-9",
  "ubuntu-2004:ubuntu-2004",
  "ubuntu-2204:ubuntu-2204",
  "rocky-8:rocky-8",
  "rocky-9:rocky-9",
  "amazon-2023:amazon-2023"
]

arm_targets = [
  "amazon-2-aarch64:centos-7",
  "centos-7-aarch64:centos-7",
  "rhel-9-aarch64:rhel-9",
  # "debian-9-aarch64:debian-9",
  "debian-10-aarch64:debian-9",
  "debian-11-aarch64:debian-9",
  "ubuntu-2004-aarch64:ubuntu-2004",
  "ubuntu-2204-aarch64:ubuntu-2204",
  # "rocky-8-aarch64:rocky-8",
  # "rocky-9-aarch64:rocky-9",
  "amazon-2023-aarch64:amazon-2023"
]

# because windows queues are very different, the target queue is very explicit.
win_targets = [
  "windows-2019:default-windows-2019",
  "windows-2022:single-use-windows-2022",
  "windows-2025:single-use-windows-2025"
]

# Update target list
targets.concat(win_targets)
targets.concat(arm_targets)

pipeline = {
  "env" => {
    "BUILD_TIMESTAMP" => Time.now.strftime("%Y-%m-%d_%H-%M-%S"),
  },
  "steps" => []
}

# if pipeline slug is chef-chef-main-validate-adhoc, then run buildkite_adhoc_metadata.sh
if ENV['BUILDKITE_PIPELINE_SLUG'].match?(/chef-chef-main-validate-(adhoc|release)/)
  pipeline["steps"] << {
    "label" => ":habicat::linux: Building Habitat package",
    "commands" => [
      "sudo -E ./.expeditor/scripts/chef_adhoc_build.sh x86_64-linux",
    ],
    "agents" => {
      "queue" => "default-privileged"
    },
    "plugins" => {
      "docker#v3.5.0" => {
        "image" => "chefes/omnibus-toolchain-centos-7:#{ENV['OMNIBUS_TOOLCHAIN_VERSION']}",
        "privileged" => true,
        "propagate-environment" => true,
        "environment" => [
          'HAB_AUTH_TOKEN'
        ]
      }
    },
    "timeout_in_minutes" => 120
  }
  pipeline["steps"] << {
    "label" => ":habicat::linux: Building ARM Habitat package",
    "commands" => [
      "sudo -E ./.expeditor/scripts/chef_adhoc_build.sh aarch64-linux",
    ],
    "agents" => {
      "queue" => "default-privileged-aarch64"
    },
    "plugins" => {
      "docker#v3.5.0" => {
        "image" => "chefes/omnibus-toolchain-ubuntu-2204:aarch64",
        "privileged" => true,
        "propagate-environment" => true,
        "environment" => [
          'HAB_AUTH_TOKEN'
        ]
      }
    },
    "timeout_in_minutes" => 120
  }
  pipeline["steps"] << {
    "label" => ":habicat::windows: Building Habitat package",
    "commands" => [
      "./.expeditor/scripts/chef_adhoc_build.ps1",
    ],
    "agents" => {
      "queue" => "default-windows-2019-privileged"
    },
    "plugins" => {
      "docker#v3.5.0" => {
        "image" => "chefes/omnibus-toolchain-windows-2019:#{ENV['OMNIBUS_TOOLCHAIN_VERSION']}",
        "shell" => [
          "powershell",
          "-Command"
        ],
        "volumes" => [
          "C:\\buildkite-agent:C:\\buildkite-agent"
        ],
        "environment" => [
          'HAB_AUTH_TOKEN',
          'BUILDKITE_AGENT_ACCESS_TOKEN',
          'AWS_ACCESS_KEY_ID',
          'AWS_SECRET_ACCESS_KEY',
          'AWS_SESSION_TOKEN',
        ],
        "propagate-environment" => true
      }
    },
    "timeout_in_minutes" => 120
  }
else
  # nightly pipeline, get package from unstable.
end

pipeline["steps"] << { "wait" => nil }

targets.each do |target|
  platform, queue_platform = target.split(":")
  step = {}

  if platform.include?("windows")
    step = {
      "label" => ":mag::windows:#{platform}",
      "key" => "validate-#{platform}",
      "retry" => {
        "automatic" => {
          "limit" => 1
        }
      },
      "agents" => {
        "queue" => "#{queue_platform}-privileged"
      },
      "plugins" => {
        "docker#v3.5.0" => {
          "image" => "chefes/omnibus-toolchain-#{platform}:#{ENV['OMNIBUS_TOOLCHAIN_VERSION']}",
          "shell" => [
            "powershell",
            "-Command"
          ],
          "volumes" => [
            "C:\\buildkite-agent:C:\\buildkite-agent"
          ],
          "environment" => [
            'HAB_AUTH_TOKEN',
            'BUILDKITE_AGENT_ACCESS_TOKEN',
            'AWS_ACCESS_KEY_ID',
            'AWS_SECRET_ACCESS_KEY',
            'AWS_SESSION_TOKEN',
          ],
          "propagate-environment" => true
        }
      },
      "commands" => [
        "./.expeditor/scripts/validate_adhoc_build.ps1"
      ],
      "timeout_in_minutes" => 120
    }
  else
    commands = ["sudo -E ./.expeditor/scripts/install-hab.sh x86_64-linux"]
    agents = {
      "queue" => "default-privileged"
    }
    docker_image = "chefes/omnibus-toolchain-#{platform}:#{ENV['OMNIBUS_TOOLCHAIN_VERSION']}"

    if platform.include?("aarch64")
      base_platform = platform.sub("-aarch64", "")
      commands = ["sudo -E ./.expeditor/scripts/install-hab.sh aarch64-linux"]
      agents["queue"] = "default-privileged-aarch64"
      docker_image = "chefes/omnibus-toolchain-#{base_platform}:aarch64"
    end
    commands << "./.expeditor/scripts/validate_adhoc_build.sh"

    step = {
      "label" => ":mag::docker:#{platform}",
      "key" => "validate-#{platform}",
      "retry" => {
        "automatic" => {
          "limit" => 1
        }
      },
      "agents" => agents,
      "plugins" => {
        "docker#v3.5.0" => {
          "image" => docker_image,
          "privileged" => true,
          "propagate-environment" => true,
          "environment" => [
            'HAB_AUTH_TOKEN'
          ]
        }
      },
      "commands" => commands,
      "timeout_in_minutes" => 120
    }
  end

  pipeline["steps"] << step
end

puts pipeline.to_yaml
