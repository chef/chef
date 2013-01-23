
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'spec_helper'

describe Chef::Resource::ConditionalActionNothing do

  describe "when created as a `not_if`" do
    describe "after running the correct action" do
      before do
        @action = :nothing
        @conditional = Chef::Resource::ConditionalActionNothing.not_if(@action)
      end

      it "indicates that resource convergence should not continue" do
        @conditional.continue?.should be_false
      end
    end

    describe "after running an incorrect action" do
      before do
        @action = :something
        @conditional = Chef::Resource::ConditionalActionNothing.not_if(@action)
      end

      it "indicates that resource convergence should continue" do
        @conditional.continue?.should be_true
      end
    end
  end

end
