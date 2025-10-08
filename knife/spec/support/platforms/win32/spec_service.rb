#
# Author:: Serdar Sutay (<serdar@lambda.local>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
  require "win32/daemon"

  class SpecService < ::Win32::Daemon
    def service_init
      @test_service_file = "#{ENV["TMP"]}/spec_service_file"
    end

    def service_main(*startup_parameters)
      while running?
        unless File.exist?(@test_service_file)
          File.open(@test_service_file, "wb") do |f|
            f.write("This file is created by SpecService")
          end
        end

        sleep 1
      end
    end

    ################################################################################
    # Control Signal Callback Methods
    ################################################################################

    def service_stop; end

    def service_pause; end

    def service_resume; end

    def service_shutdown; end
  end

  # To run this file as a service, it must be called as a script from within
  # the Windows Service framework.  In that case, kick off the main loop!
  if __FILE__ == $0
    SpecService.mainloop
  end
end
