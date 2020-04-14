#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

shared_examples_for "a knife key command" do
  let(:stderr) { StringIO.new }
  let(:command) do
    c = described_class.new([])
    c.ui.config[:disable_editing] = true
    allow(c.ui).to receive(:stderr).and_return(stderr)
    allow(c.ui).to receive(:stdout).and_return(stderr)
    allow(c).to receive(:show_usage)
    c
  end

  context "before apply_params! is called" do
    context "when apply_params! is called with invalid args (missing actor)" do
      let(:params) { [] }
      it "shows the usage" do
        expect(command).to receive(:show_usage)
        expect { command.apply_params!(params) }.to exit_with_code(1)
      end

      it "outputs the proper error" do
        expect { command.apply_params!(params) }.to exit_with_code(1)
        expect(stderr.string).to include(command.actor_missing_error)
      end

      it "exits 1" do
        expect { command.apply_params!(params) }.to exit_with_code(1)
      end
    end
  end # before apply_params! is called

  context "after apply_params! is called with valid args" do
    before do
      command.apply_params!(params)
    end

    it "properly defines the actor" do
      expect(command.actor).to eq("charmander")
    end
  end # after apply_params! is called with valid args

  context "when the command is run" do
    before do
      allow(command).to receive(:service_object).and_return(service_object)
      allow(command).to receive(:name_args).and_return(["charmander"])
    end

    context "when the command is successful" do
      before do
        expect(service_object).to receive(:run)
      end
    end
  end
end # a knife key command

shared_examples_for "a knife key command with a keyname as the second arg" do
  let(:stderr) { StringIO.new }
  let(:command) do
    c = described_class.new([])
    c.ui.config[:disable_editing] = true
    allow(c.ui).to receive(:stderr).and_return(stderr)
    allow(c.ui).to receive(:stdout).and_return(stderr)
    allow(c).to receive(:show_usage)
    c
  end

  context "before apply_params! is called" do
    context "when apply_params! is called with invalid args (missing keyname)" do
      let(:params) { ["charmander"] }
      it "shows the usage" do
        expect(command).to receive(:show_usage)
        expect { command.apply_params!(params) }.to exit_with_code(1)
      end

      it "outputs the proper error" do
        expect { command.apply_params!(params) }.to exit_with_code(1)
        expect(stderr.string).to include(command.keyname_missing_error)
      end

      it "exits 1" do
        expect { command.apply_params!(params) }.to exit_with_code(1)
      end
    end
  end # before apply_params! is called
end
