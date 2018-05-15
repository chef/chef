#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module ChefConfig

  def self.fips?
    if ChefConfig.windows?
      begin
        require "win32/registry"
      rescue LoadError
        return false
      end

      # from http://msdn.microsoft.com/en-us/library/windows/desktop/aa384129(v=vs.85).aspx
      reg_type =
        case ::RbConfig::CONFIG["target_cpu"]
        when "i386"
          Win32::Registry::KEY_READ | 0x100
        when "x86_64"
          Win32::Registry::KEY_READ | 0x200
        else
          Win32::Registry::KEY_READ
        end
      begin
        Win32::Registry::HKEY_LOCAL_MACHINE.open('System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy', reg_type) do |policy|
          policy["Enabled"] != 0
        end
      rescue Win32::Registry::Error
        false
      end
    else
      fips_path = "/proc/sys/crypto/fips_enabled"
      File.exist?(fips_path) && File.read(fips_path).chomp != "0"
    end
  end
end
