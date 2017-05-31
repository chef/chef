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
      stub_const("Chef::VERSION", "1.2.3")
      stub_const("RUBY_DESCRIPTION", "ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]")
      allow(subject).to receive(:caller) { Kernel.caller + ["/test/bin/chef-client:1:in `<main>'"] }
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/test/bin/chef-client").and_return("/test/bin/chef-client")
    end

    around do |ex|
      old_program_name = $PROGRAM_NAME
      begin
        $PROGRAM_NAME = "chef-client"
        ex.run
      ensure
        $PROGRAM_NAME = old_program_name
      end
    end

    context "when no sections have been added" do
      it "should output only the title and the Platform section" do
        subject.display(out)
        expect(out.out.string).to eq <<-END
================================================================================
test title
================================================================================

System Info:
------------
chef_version=1.2.3
ruby=ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]
program_name=chef-client
executable=/test/bin/chef-client

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

System Info:
------------
chef_version=1.2.3
ruby=ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]
program_name=chef-client
executable=/test/bin/chef-client

        END
      end

    end

    context "when node object is available" do
      it "should output the expected sections" do
        # This can't be in a before block because the spec-wide helper calls a
        # reset on global values.
        Chef.set_node({ "platform" => "openvms", "platform_version" => "8.4-2L1" })
        subject.display(out)
        expect(out.out.string).to eq <<-END
================================================================================
test title
================================================================================

System Info:
------------
chef_version=1.2.3
platform=openvms
platform_version=8.4-2L1
ruby=ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]
program_name=chef-client
executable=/test/bin/chef-client

        END
      end

    end
  end
end
