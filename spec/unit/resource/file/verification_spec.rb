#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc
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

describe Chef::Resource::File::Verification do
  let(:t_block) { Proc.new { true } }
  let(:f_block) { Proc.new { false } }
  let(:path_block) { Proc.new { |path| path } }
  let(:temp_path) { "/tmp/foobar" }

  describe "verification registration" do
    it "registers a verification for later use" do
      class Chef::Resource::File::Verification::Wombat < Chef::Resource::File::Verification
        provides :tabmow
      end
      expect(Chef::Resource::File::Verification.lookup(:tabmow)).to eq(Chef::Resource::File::Verification::Wombat)
    end

    it "raises an error if a verification can't be found" do
      expect { Chef::Resource::File::Verification.lookup(:dne) }.to raise_error(Chef::Exceptions::VerificationNotFound)
    end
  end

  describe "#verify" do
    let(:parent_resource) { Chef::Resource.new("llama") }

    it "expects a string argument" do
      v = Chef::Resource::File::Verification.new(parent_resource, nil, {}) {}
      expect { v.verify("/foo/bar") }.to_not raise_error
      expect { v.verify }.to raise_error(ArgumentError)
    end

    it "accepts an options hash" do
      v = Chef::Resource::File::Verification.new(parent_resource, nil, {}) {}
      expect { v.verify("/foo/bar", { :future => true }) }.to_not raise_error
    end

    context "with a verification block" do
      it "passes a file path to the block" do
        v = Chef::Resource::File::Verification.new(parent_resource, nil, {}, &path_block)
        expect(v.verify(temp_path)).to eq(temp_path)
      end

      it "returns true if the block returned true" do
        v = Chef::Resource::File::Verification.new(parent_resource, nil, {}, &t_block)
        expect(v.verify(temp_path)).to eq(true)
      end

      it "returns false if the block returned false" do
        v = Chef::Resource::File::Verification.new(parent_resource, nil, {}, &f_block)
        expect(v.verify(temp_path)).to eq(false)
      end
    end

    context "with a verification command(String)" do
      before(:each) do
        allow(Chef::Log).to receive(:deprecation).and_return(nil)
      end

      def platform_specific_verify_command(variable_name)
        if windows?
          "if \"#{temp_path}\" == \"%{#{variable_name}}\" (exit 0) else (exit 1)"
        else
          "test #{temp_path} = %{#{variable_name}}"
        end
      end

      it "raises an error when \%{file} is used" do
        test_command = platform_specific_verify_command("file")
        expect do
          Chef::Resource::File::Verification.new(parent_resource, test_command, {}).verify(temp_path)
        end.to raise_error(ArgumentError)
      end

      it "does not raise an error when \%{file} is not used" do
        test_command = platform_specific_verify_command("path")
        expect do
          Chef::Resource::File::Verification.new(parent_resource, test_command, {}).verify(temp_path)
        end.to_not raise_error
      end

      it "substitutes \%{path} with the path" do
        test_command = platform_specific_verify_command("path")
        v = Chef::Resource::File::Verification.new(parent_resource, test_command, {})
        expect(v.verify(temp_path)).to eq(true)
      end

      it "returns false if the command fails" do
        v = Chef::Resource::File::Verification.new(parent_resource, "false", {})
        expect(v.verify(temp_path)).to eq(false)
      end

      it "returns true if the command succeeds" do
        v = Chef::Resource::File::Verification.new(parent_resource, "true", {})
        expect(v.verify(temp_path)).to eq(true)
      end
    end

    context "with a named verification(Symbol)" do
      before(:each) do
        class Chef::Resource::File::Verification::Turtle < Chef::Resource::File::Verification
          provides :cats
          def verify(path, opts)
          end
        end
      end

      it "delegates to the registered verification" do
        registered_verification = double()
        allow(Chef::Resource::File::Verification::Turtle).to receive(:new).and_return(registered_verification)
        v = Chef::Resource::File::Verification.new(parent_resource, :cats, {})
        expect(registered_verification).to receive(:verify).with(temp_path, {})
        v.verify(temp_path, {})
      end
    end
  end
end
