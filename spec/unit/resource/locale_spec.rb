#
# Author:: Vincent AUBERT (<vincentaubert88@gmail.com>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

describe Chef::Resource::Locale do
  let(:resource) { Chef::Resource::Locale.new("fakey_fakerton") }

  it "has a name of locale" do
    expect(resource.resource_name).to eq(:locale)
  end

  it "supports :update action" do
    expect { resource.action :update }.not_to raise_error
  end

  context "Default" do
    it "lang: nil" do
      expect(resource.lang).to be_nil
    end
    it "lc_all: nil" do
      expect(resource.lc_all).to be_nil
    end
    it "action: :update" do
      expect(resource.action).to eql([:update])
    end
  end

  context "When lang is set" do
    before do
      resource.lang("fr_FR.utf8")
    end
    it "the lang property is set" do
      expect(resource.lang).to eql("fr_FR.utf8")
    end
    it "the lc_all property remains nil" do
      expect(resource.lc_all).to be_nil
    end
  end

  context "When lc_all is set" do
    before do
      resource.lc_all("fr_FR.utf8")
    end
    it "the lang property remains nil" do
      expect(resource.lang).to be_nil
    end
    it "the lc_all property is set" do
      expect(resource.lc_all).to eql("fr_FR.utf8")
    end
  end

  context "When property is set" do
    before do
      resource.lang("fr_FR.utf8")
      resource.lc_all("fr_FR.utf8")
    end
    it "the lang property is set" do
      expect(resource.lang).to eql("fr_FR.utf8")
    end
    it "the lc_all property is set" do
      expect(resource.lc_all).to eql("fr_FR.utf8")
    end
  end

  should_not_change = <<-ENVFILE
  An example file
    with some tabs,
  LC_ALL

  next lines,
  # Comments
  and most important, LANG = as some value. Hey,
  did you noticed those whitespaces.?
          and lets put
  some another LC_ALL = as some random value.
  LANG =
  FILE ENDS HERE

  ENVFILE

  [
    {
      "Setting LANG" => {
        lang: "X",
        lc_all: nil,
        cases: [
          {
            context: "In empty file",
            actual: "",
            up_to_date: false,
            expected: '
LANG=X #created by chef
',
          },
          {
            context: "In a file having same LANG",
            actual: should_not_change + '
            LANG=X',
            up_to_date: true,
            expected: should_not_change + '
            LANG=X',
          },
          {
            context: "In a file having different LANG",
            actual: should_not_change + '
            LANG=Z
            ',
            up_to_date: false,
            expected: should_not_change + '

LANG=X #created by chef
            ',
          },
          {
            context: "In a file having LC_ALL",
            actual: should_not_change + '
            LC_ALL=Y',
            up_to_date: false,
            expected: should_not_change + '
            LC_ALL=Y
LANG=X #created by chef
',
          },
          {
            context: "In a file having different LC_ALL",
            actual: should_not_change + '
            LC_ALL=Z',
            up_to_date: false,
            expected: should_not_change + '
            LC_ALL=Z
LANG=X #created by chef
',
          },
          {
            context: "In a file having different LANG and different LC_ALL",
            actual: '
            LANG=bar
            LC_ALL=foo
            ' + should_not_change,
            up_to_date: false,
            expected: '

LANG=X #created by chef
            LC_ALL=foo
            ' + should_not_change,
          },
          {
            context: "In a file having different LANG and different LC_ALL & whitespaces",
            actual: '
            LC_ALL = foo
            LANG = bar
            ' + should_not_change,
            up_to_date: false,
            expected: '
            LC_ALL = foo

LANG=X #created by chef
            ' + should_not_change,
          }
        ],
      },
    },
    {
      "Setting LC_ALL" => {
        lang: nil,
        lc_all: "Y",
        cases: [
          {
            context: "In empty file",
            actual: "",
            up_to_date: false,
            expected: '
LC_ALL=Y #created by chef
',
          },
          {
            context: "In a file having same LANG",
            actual: should_not_change + '
            LANG=X',
            up_to_date: false,
            expected: should_not_change + '
            LANG=X
LC_ALL=Y #created by chef
',
          },
          {
            context: "In a file having different LANG",
            actual: should_not_change + '
            LANG=Z',
            up_to_date: false,
            expected: should_not_change + '
            LANG=Z
LC_ALL=Y #created by chef
',
          },
          {
            context: "In a file having same LC_ALL",
            actual: should_not_change + '
            LC_ALL=Y
            ',
            up_to_date: true,
            expected: should_not_change + '
            LC_ALL=Y
            ',
          },
          {
            context: "In a file having different LC_ALL",
            actual: should_not_change + '
            LC_ALL=Z
            ',
            up_to_date: false,
            expected: should_not_change + '

LC_ALL=Y #created by chef
            ',
          },
          {
            context: "In a file having different LANG and different LC_ALL",
            actual: '
            LANG=bar
            LC_ALL=foo
            ' + should_not_change,
            up_to_date: false,
            expected: '
            LANG=bar

LC_ALL=Y #created by chef
            ' + should_not_change,
          },
          {
            context: "In a file having different LANG and different LC_ALL & whitespaces",
            actual: '
            LC_ALL = foo
            LANG = bar
            ' + should_not_change,
            up_to_date: false,
            expected: '

LC_ALL=Y #created by chef
            LANG = bar
            ' + should_not_change,
          }
        ],
      },
    },
    {
      "Setting LANG and LC_ALL" => {
        lang: "X",
        lc_all: "Y",
        cases: [
          {
            context: "In empty file",
            actual: "",
            up_to_date: false,
            expected: '
LANG=X #created by chef

LC_ALL=Y #created by chef
',
          },
            {
              context: "In a file having same LANG",
              actual: should_not_change + '
              LANG=X',
              up_to_date: false,
              expected: should_not_change + '
              LANG=X
LC_ALL=Y #created by chef
',
            },
          {
            context: "In a file having different LANG",
            actual: should_not_change + '
            LANG=Z',
            up_to_date: false,
            expected: should_not_change + '

LANG=X #created by chef

LC_ALL=Y #created by chef
',
          },
          {
            context: "In a file having same LC_ALL",
            actual: should_not_change + '
            LC_ALL=Y',
            up_to_date: false,
            expected: should_not_change + '
            LC_ALL=Y
LANG=X #created by chef
',
          },
          {
            context: "In a file having different LC_ALL",
            actual: should_not_change + '
            LC_ALL=Z',
            up_to_date: false,
            expected: should_not_change + '

LC_ALL=Y #created by chef

LANG=X #created by chef
',
          },
          {
            context: "In a file having different LANG and different LC_ALL",
            actual: '
            LC_ALL=foo
            LANG=bar
            ' + should_not_change,
            up_to_date: false,
            expected: '

LC_ALL=Y #created by chef

LANG=X #created by chef
            ' + should_not_change,
          },
          {
            context: "In a file having different LANG and different LC_ALL & whitespaces",
            actual: '
            LC_ALL = foo
            LANG = bar
            ' + should_not_change,
            up_to_date: false,
            expected: '

LC_ALL=Y #created by chef

LANG=X #created by chef
            ' + should_not_change,
          },
          {
            context: "In a file having different LANG and different LC_ALL, whitespaces & Inline comments",
            actual: should_not_change + '
            # this is a comment
            LC_ALL="value" # comment
            LANG=value # comment
            ' + should_not_change,
            up_to_date: false,
            expected: should_not_change + '
            # this is a comment

LC_ALL=Y #created by chef

LANG=X #created by chef
            ' + should_not_change,
          },
          {
            context: "In a file having different LANG and different LC_ALL, Whitespaces, Comments, underscores and dots",
            actual: should_not_change + '
            # this is a comment
            LC_ALL = "Some.Value_X" # comment
              LANG=value1_VAL2.XX # comment
            ' + should_not_change,
            up_to_date: false,
            expected: should_not_change + '
            # this is a comment

LC_ALL=Y #created by chef

LANG=X #created by chef
            ' + should_not_change,
          }
        ],
      },
    }
  ].each do |t|
    t.each do |desc, test_case|
      describe desc do
        let(:lang) { test_case[:lang] }
        let(:lc_all) { test_case[:lc_all] }
        test_case[:cases].each do |t_case|
          context t_case[:context] do
            let(:contents) { t_case[:actual] }
            describe "#up_to_date?" do
              subject { resource.up_to_date?(contents, lang, lc_all) }
              it { is_expected.to be(t_case[:up_to_date]) }
            end
            describe "#add_or_replace" do
              subject { resource.add_or_replace(contents, lang, lc_all) }
              it "returns expected string" do
                expect(subject).to eq(t_case[:expected])
                # expect(subject).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
