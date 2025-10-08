# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright 2013-2016, Onddo Labs, SL.
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
require_relative "../version_constraint"
require_relative "../version/platform"

# NOTE: this is fairly badly broken for its purpose and should not be used
#       unless it gets fixed.  see chef/version/platform.
class Chef
  class VersionConstraint
    class Platform < Chef::VersionConstraint
      VERSION_CLASS = Chef::Version::Platform

    end
  end
end
