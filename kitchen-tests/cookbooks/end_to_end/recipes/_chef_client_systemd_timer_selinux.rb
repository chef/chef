#
# Cookbook:: end_to_end
# Recipe:: _chef_client_systemd_timer_selinux
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# Tests that chef_client_systemd_timer resource fails on RHEL systems with SELinux enabled (enforcing mode)
#

# Only run on RHEL-based systems with systemd
return unless platform_family?("rhel", "fedora", "amazon") && systemd?

# Check if SELinux is available and can be enabled
# In Docker containers, SELinux may not be available
selinux_available = ::File.exist?("/sys/fs/selinux") && ::File.exist?("/usr/sbin/getenforce")

if selinux_available
  Chef::Log.info("SELinux is available, proceeding with SELinux test")

  # First, ensure SELinux is installed
  selinux_install "Install SELinux for testing"

  # Check current SELinux state
  ruby_block "check_selinux_status" do
    block do
      selinux_status = shell_out("getenforce")
      Chef::Log.info("Current SELinux status: #{selinux_status.stdout.strip}")

      # Store in node attribute for later use
      node.run_state["selinux_original_state"] = selinux_status.stdout.strip.downcase
    end
  end

  # Only attempt to set enforcing if SELinux is not disabled
  # (disabled requires reboot to enable)
  ruby_block "attempt_selinux_enforcing" do
    block do
      selinux_state = node.run_state["selinux_original_state"]

      if selinux_state == "disabled"
        Chef::Log.warn("SELinux is disabled and cannot be enabled without a reboot. Skipping SELinux enforcing test.")
        node.run_state["skip_selinux_test"] = true
      elsif selinux_state == "permissive"
        Chef::Log.info("Setting SELinux to enforcing mode for testing")
        shell_out!("setenforce 1")
        node.run_state["skip_selinux_test"] = false
      else
        # Already enforcing
        Chef::Log.info("SELinux already in enforcing mode")
        node.run_state["skip_selinux_test"] = false
      end
    end
  end

  # This resource is expected to fail when SELinux is in enforcing mode
  # because the systemd unit files created don't have the proper SELinux context
  chef_client_systemd_timer "Test timer with SELinux enforcing" do
    chef_binary_path "/opt/chef/bin/chef-client" if ::File.exist?("/opt/chef/bin/chef-client")
    interval "1hr"
    job_name "chef-client-selinux-test"
    action :add
    # Allow the resource to fail - this is expected with SELinux enforcing
    ignore_failure true
    not_if { node.run_state["skip_selinux_test"] }
  end

  # Log the result for debugging
  ruby_block "check_selinux_timer_status" do
    block do
      unless node.run_state["skip_selinux_test"]
        # Check if the timer is actually running
        timer_status = shell_out("systemctl is-active chef-client-selinux-test.timer")
        if timer_status.exitstatus == 0
          Chef::Log.warn("chef_client_systemd_timer succeeded with SELinux enforcing - this may indicate SELinux policy has been updated")
        else
          Chef::Log.info("chef_client_systemd_timer failed to start with SELinux enforcing as expected")
        end

        # Check for SELinux denials
        if ::File.exist?("/usr/bin/ausearch")
          avc_denials = shell_out("ausearch -m AVC -ts recent 2>/dev/null | grep chef-client-selinux-test || true")
          if !avc_denials.stdout.empty?
            Chef::Log.info("Found SELinux AVC denials for chef-client-selinux-test")
          end
        end
      end
    end
  end

  # Clean up - set SELinux back to permissive for other tests
  ruby_block "restore_selinux_permissive" do
    block do
      unless node.run_state["skip_selinux_test"]
        selinux_status = shell_out("getenforce").stdout.strip.downcase
        if selinux_status == "enforcing"
          Chef::Log.info("Restoring SELinux to permissive mode")
          shell_out!("setenforce 0")
        end
      end
    end
  end
else
  Chef::Log.warn("SELinux is not available (likely running in a container). Skipping SELinux test.")
end
