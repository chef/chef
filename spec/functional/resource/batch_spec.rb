#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::Resource::WindowsScript::Batch, :windows_only do
  include_context Chef::Resource::WindowsScript

  let(:output_command) { " > " }

  let(:architecture_command) { "@echo %PROCESSOR_ARCHITECTURE%" }

  let(:resource) do
    Chef::Resource::WindowsScript::Batch.new("Batch resource functional test", @run_context)
  end

  it_behaves_like "a Windows script running on Windows"

end
