#
#  Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
# li

def hab(*command)
  # Windows shell_out does not support arrays, so manually cleaning and joining
  hab_cmd = if windows?
              (["hab"] + command).flatten.compact.join(" ")
            else
              (["hab"] + command)
            end
  shell_out!(hab_cmd)
rescue Errno::ENOENT
  Chef::Log.fatal("'hab' binary not found, use the 'habitat_install' resource to install it first")
  raise
end
