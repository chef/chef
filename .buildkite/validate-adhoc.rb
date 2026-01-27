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
  "centos-7-arm:centos-7-arm",
  "amazon-2-arm:amazon-2-arm",
  "rhel-9-arm:rhel-9-arm",
  "ubuntu-1804-arm:ubuntu-1804-arm",
  "ubuntu-2004-arm:ubuntu-2004-arm",
  "ubuntu-2204-arm:ubuntu-2204-arm",
  "amazon-2023-arm:amazon-2023-arm"
]

# because windows queues are very different, the target queue is very explicit.
win_targets = [
  "windows-2019:default-windows-2019",
  "windows-2022:single-use-windows-2022",
  "windows-2025:single-use-windows-2025"
]

# Update target list
targets.concat(win_targets)

if ENV['ARM_ENABLED'] == '1'
  targets.concat(arm_targets)
end

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
      "sudo -E ./.expeditor/scripts/chef_adhoc_build.sh",
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
    commands = ["sudo ./.expeditor/scripts/install-hab.sh x86_64-linux"]
    agents = {
      "queue" => "default-privileged"
    }

    if platform.include?("arm")
      commands = ["sudo ./.expeditor/scripts/install-hab.sh <arm>"]
      agents["queue"] = "docker-linux-arm64"
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
          "image" => "chefes/omnibus-toolchain-#{platform}:#{ENV['OMNIBUS_TOOLCHAIN_VERSION']}",
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
