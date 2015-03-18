
require 'chef/application/windows_service_manager'

shared_context "using Win32::Service" do
  # Some helper methods.

  def test_service_exists?
    ::Win32::Service.exists?("spec-service")
  end

  def test_service_state
    ::Win32::Service.status("spec-service").current_state
  end

  def service_manager
    Chef::Application::WindowsServiceManager.new(test_service)
  end

  def cleanup
    # Uninstall if the test service is installed.
    if test_service_exists?

      # We can only uninstall when the service is stopped.
      if test_service_state != "stopped"
        ::Win32::Service.send("stop", "spec-service")
        while test_service_state != "stopped"
          sleep 1
        end
      end

      ::Win32::Service.delete("spec-service")
    end

    # Delete the test_service_file if it exists
    if File.exists?(test_service_file)
      File.delete(test_service_file)
    end

  end


  # Definition for the test-service

  let(:test_service) {
    {
      :service_name => "spec-service",
      :service_display_name => "Spec Test Service",
      :service_description => "Service for testing Chef::Application::WindowsServiceManager.",
      :service_file_path => File.expand_path(File.join(File.dirname(__FILE__), '../../platforms/win32/spec_service.rb'))
    }
  }

  # Test service creates a file for us to verify that it is running.
  # Since our test service is running as Local System we should look
  # for the file it creates under SYSTEM temp directory

  let(:test_service_file) {
    "#{ENV['SystemDrive']}\\windows\\temp\\spec_service_file"
  }
end
