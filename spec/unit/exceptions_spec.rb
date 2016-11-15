#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright 2010-2016, Thomas Bishop
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Chef::Exceptions do
  exception_to_super_class = {
    Chef::Exceptions::Application => RuntimeError,
    Chef::Exceptions::Cron => RuntimeError,
    Chef::Exceptions::Env => RuntimeError,
    Chef::Exceptions::Exec => RuntimeError,
    Chef::Exceptions::FileNotFound => RuntimeError,
    Chef::Exceptions::Package => RuntimeError,
    Chef::Exceptions::Service => RuntimeError,
    Chef::Exceptions::Route => RuntimeError,
    Chef::Exceptions::SearchIndex => RuntimeError,
    Chef::Exceptions::Override => RuntimeError,
    Chef::Exceptions::UnsupportedAction => RuntimeError,
    Chef::Exceptions::MissingLibrary => RuntimeError,
    Chef::Exceptions::MissingRole => RuntimeError,
    Chef::Exceptions::CannotDetermineNodeName => RuntimeError,
    Chef::Exceptions::User => RuntimeError,
    Chef::Exceptions::Group => RuntimeError,
    Chef::Exceptions::Link => RuntimeError,
    Chef::Exceptions::Mount => RuntimeError,
    Chef::Exceptions::PrivateKeyMissing => RuntimeError,
    Chef::Exceptions::CannotWritePrivateKey => RuntimeError,
    Chef::Exceptions::RoleNotFound => RuntimeError,
    Chef::Exceptions::ValidationFailed => ArgumentError,
    Chef::Exceptions::InvalidPrivateKey => ArgumentError,
    Chef::Exceptions::ConfigurationError => ArgumentError,
    Chef::Exceptions::RedirectLimitExceeded => RuntimeError,
    Chef::Exceptions::AmbiguousRunlistSpecification => ArgumentError,
    Chef::Exceptions::CookbookNotFound => RuntimeError,
    Chef::Exceptions::AttributeNotFound => RuntimeError,
    Chef::Exceptions::InvalidCommandOption => RuntimeError,
    Chef::Exceptions::CommandTimeout => RuntimeError,
    Mixlib::ShellOut::ShellCommandFailed => RuntimeError,
    Chef::Exceptions::RequestedUIDUnavailable => RuntimeError,
    Chef::Exceptions::InvalidHomeDirectory => ArgumentError,
    Chef::Exceptions::DsclCommandFailed => RuntimeError,
    Chef::Exceptions::UserIDNotFound => ArgumentError,
    Chef::Exceptions::GroupIDNotFound => ArgumentError,
    Chef::Exceptions::InvalidResourceReference => RuntimeError,
    Chef::Exceptions::ResourceNotFound => RuntimeError,
    Chef::Exceptions::InvalidResourceSpecification => ArgumentError,
    Chef::Exceptions::SolrConnectionError => RuntimeError,
    Chef::Exceptions::InvalidDataBagPath => ArgumentError,
    Chef::Exceptions::InvalidEnvironmentPath => ArgumentError,
    Chef::Exceptions::EnvironmentNotFound => RuntimeError,
    Chef::Exceptions::InvalidVersionConstraint => ArgumentError,
    Chef::Exceptions::IllegalVersionConstraint => RuntimeError,
    Chef::Exceptions::RegKeyValuesTypeMissing => ArgumentError,
    Chef::Exceptions::RegKeyValuesDataMissing => ArgumentError,
  }

  exception_to_super_class.each do |exception, expected_super_class|
    it "should have an exception class of #{exception} which inherits from #{expected_super_class}" do
      expect { raise exception }.to raise_error(expected_super_class)
    end

    if exception.methods.include?(:to_json)
      include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
        let(:jsonable) { exception }
      end
    end
  end

  describe Chef::Exceptions::RunFailedWrappingError do
    shared_examples "RunFailedWrappingError expectations" do
      it "should initialize with a default message" do
        expect(e.message).to eq("Found #{num_errors} errors, they are stored in the backtrace")
      end

      it "should provide a modified backtrace when requested" do
        e.fill_backtrace
        expect(e.backtrace).to eq(backtrace)
      end
    end

    context "initialized with nothing" do
      let(:e) { Chef::Exceptions::RunFailedWrappingError.new }
      let(:num_errors) { 0 }
      let(:backtrace) { [] }

      include_examples "RunFailedWrappingError expectations"
    end

    context "initialized with nil" do
      let(:e) { Chef::Exceptions::RunFailedWrappingError.new(nil, nil) }
      let(:num_errors) { 0 }
      let(:backtrace) { [] }

      include_examples "RunFailedWrappingError expectations"
    end

    context "initialized with 1 error and nil" do
      let(:e) { Chef::Exceptions::RunFailedWrappingError.new(RuntimeError.new("foo"), nil) }
      let(:num_errors) { 1 }
      let(:backtrace) { ["1) RuntimeError -  foo"] }

      include_examples "RunFailedWrappingError expectations"
    end

    context "initialized with 2 errors" do
      let(:e) { Chef::Exceptions::RunFailedWrappingError.new(RuntimeError.new("foo"), RuntimeError.new("bar")) }
      let(:num_errors) { 2 }
      let(:backtrace) { ["1) RuntimeError -  foo", "", "2) RuntimeError -  bar"] }

      include_examples "RunFailedWrappingError expectations"
    end

  end
end
