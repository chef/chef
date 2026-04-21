#
# Copyright:: Copyright (c) Chef Software Inc.
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

name "aix-installp-cleanup"

license :project_license
skip_transitive_dependency_licensing true

# Clear any incomplete installp state on AIX before chef-foundation is
# installed.  When a Buildkite build is cancelled mid-install (SIGKILL),
# installp can be left in a partial state that causes the next invocation
# to error: "0503-434 installp: There are incomplete installation operations".
# Running 'installp -C' commits or rolls back the partial state cleanly.
# Safe to run unconditionally: exits 0 immediately if no cleanup is needed.
build do
  # Use a shell-level test so this is evaluated on the remote build host
  # (AIX), not on the Linux jump box where the omnibus Ruby DSL is parsed.
  # On AIX: /usr/sbin/installp exists → runs installp -C to clear incomplete state.
  # On Linux/macOS: /usr/sbin/installp absent → test -f fails, command is a no-op.
  command "test -f /usr/sbin/installp && sudo /usr/sbin/installp -C 2>/dev/null; true"
end
