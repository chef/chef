#
# Author:: Jordan Running (<jr@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

describe Chef::Formatters::ErrorDescription do
  let(:title) { "test title" }

  let(:out) { Chef::Formatters::IndentableOutputStream.new(StringIO.new, STDERR) }

  let(:section_heading) { "test heading" }
  let(:section_text) { "test text" }

  subject { Chef::Formatters::ErrorDescription.new(title) }

  describe "#sections" do
    context "when no sections have been added" do
      it "should return an empty array" do
        expect(subject.sections).to eq []
      end
    end

    context "when a section has been added" do
      before do
        subject.section(section_heading, section_text)
      end

      it "should return an array with the added section as a hash" do
        expect(subject.sections).to eq [ { section_heading => section_text } ]
      end
    end
  end

  describe "#display" do
    before do
      stub_const("RUBY_PLATFORM", "ruby-foo-9000")
    end

    context "when no sections have been added" do
      it "should output only the title and the Platform section" do
        subject.display(out)
        expect(out.out.string).to eq <<-END
================================================================================
test title
================================================================================

Platform:
---------
ruby-foo-9000

        END
      end
    end

    context "when a section has been added" do
      before do
        subject.section(section_heading, section_text)
      end

      it "should output the expected sections" do
        subject.display(out)
        expect(out.out.string).to eq <<-END
================================================================================
test title
================================================================================

test heading
------------
test text

Platform:
---------
ruby-foo-9000

        END
      end

    end
  end
end
