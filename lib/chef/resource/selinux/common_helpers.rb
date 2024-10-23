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
class Chef
  module SELinux
    module CommonHelpers
      def selinux_disabled?
        selinux_state.eql?(:disabled)
      end

      def selinux_enforcing?
        selinux_state.eql?(:enforcing)
      end

      def selinux_permissive?
        selinux_state.eql?(:permissive)
      end

      def state_change_reboot_required?
        (selinux_disabled? && %i{enforcing permissive}.include?(action)) || ((selinux_enforcing? || selinux_permissive?) && action == :disabled)
      end

      def selinux_state
        state = shell_out!("getenforce").stdout.strip.downcase.to_sym
        raise "Got unknown SELinux state #{state}" unless %i{disabled enforcing permissive}.include?(state)

        state
      end

      def selinux_activate_required?
        return false unless platform_family?("debian")

        !TargetIO::File.read("/etc/default/grub").match?("security=selinux")
      end
    end
  end
end
