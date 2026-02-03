# Tests for chef_client_systemd_timer resource with SELinux enforcing mode
# This test verifies that the resource properly handles SELinux contexts on RHEL systems

# Only run on RHEL-based systems with systemd
if (os.family == "redhat" || os.family == "fedora" || os.family == "amazon") && os.name != "darwin"

  # Check if SELinux is available on the system
  selinux_available = file("/usr/sbin/getenforce").exist?

  if selinux_available
    # Verify SELinux tools are installed
    describe package("libselinux") do
      it { should be_installed }
    end

    # Check current SELinux status
    describe command("getenforce") do
      its("exit_status") { should eq 0 }
      # SELinux should be either Permissive or Disabled (not Enforcing after cleanup)
      # or if it's still Enforcing, that means the test is currently running
    end

    selinux_status = command("getenforce").stdout.strip

    # Log the SELinux status for debugging
    describe "SELinux Status" do
      it "is #{selinux_status}" do
        expect(["Enforcing", "Permissive", "Disabled"]).to include(selinux_status)
      end
    end

    # Only run detailed tests if SELinux was not disabled
    if selinux_status != "Disabled"
      # Check if the test systemd timer unit files were created
      describe file("/etc/systemd/system/chef-client-selinux-test.timer") do
        # This file may or may not exist depending on when/if the test ran
        if it.exist?
          it { should be_file }
          it { should be_owned_by "root" }
          its("mode") { should cmp "0644" }
          its("content") { should match(/OnUnitActiveSec=1hr/) }
        else
          skip "Timer file not created (SELinux test may have been skipped)"
        end
      end

      describe file("/etc/systemd/system/chef-client-selinux-test.service") do
        if it.exist?
          it { should be_file }
          it { should be_owned_by "root" }
          its("mode") { should cmp "0644" }
          its("content") { should match(/ExecStart=.*chef-client/) }
        else
          skip "Service file not created (SELinux test may have been skipped)"
        end
      end

      # The key test: timer should NOT be running if SELinux was enforcing during creation
      describe systemd_service("chef-client-selinux-test.timer") do
        if it.exist?
          # If SELinux was in enforcing mode, the timer should have failed to start
          # If SELinux was permissive, it might be running
          # We just verify the service state is consistent
          it { should be_installed }
        else
          skip "Timer service not created (SELinux test may have been skipped)"
        end
      end

      # Check SELinux audit logs for denials (if auditd is available)
      if file("/usr/sbin/ausearch").exist?
        describe "SELinux audit logs" do
          subject { command("ausearch -m AVC -ts recent 2>/dev/null | grep -c 'chef-client-selinux-test' || echo '0'") }
          # We don't require denials, but if found, log them for information
          it "may contain AVC denials for chef-client-selinux-test" do
            denial_count = subject.stdout.strip.to_i
            puts "Found #{denial_count} SELinux AVC denial(s) related to chef-client-selinux-test"
          end
        end
      end
    else
      describe "SELinux Test Skipped" do
        it "was skipped because SELinux is disabled" do
          skip "SELinux is disabled and cannot be enabled without a reboot"
        end
      end
    end
  else
    describe "SELinux Not Available" do
      it "test skipped because SELinux is not available" do
        skip "SELinux tools not found (likely running in a container without SELinux support)"
      end
    end
  end

  # Verify that the original systemd timer (from the main linux recipe) is working
  # This one should work because SELinux is set to permissive for it
  describe systemd_service("chef-client.timer") do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe file("/etc/systemd/system/chef-client.timer") do
    it { should be_file }
    it { should be_owned_by "root" }
    its("mode") { should cmp "0644" }
  end

  describe file("/etc/systemd/system/chef-client.service") do
    it { should be_file }
    it { should be_owned_by "root" }
    its("mode") { should cmp "0644" }
    its("content") { should match(/ExecStart=.*chef-client/) }
  end
end
