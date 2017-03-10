#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

class ConvertToClassTestHarness
  include Chef::Mixin::ConvertToClassName
end

describe Chef::Mixin::ConvertToClassName do

  before do
    @convert = ConvertToClassTestHarness.new
  end

  it "converts a_snake_case_word to a CamelCaseWord" do
    expect(@convert.convert_to_class_name("now_camelized")).to eq("NowCamelized")
  end

  it "converts a CamelCaseWord to a snake_case_word" do
    expect(@convert.convert_to_snake_case("NowImASnake")).to eq("now_im_a_snake")
  end

  it "removes the base classes before snake casing" do
    expect(@convert.convert_to_snake_case("NameSpaced::Class::ThisIsWin", "NameSpaced::Class")).to eq("this_is_win")
  end

  it "removes the base classes without explicitly naming them and returns snake case" do
    expect(@convert.snake_case_basename("NameSpaced::Class::ExtraWin")).to eq("extra_win")
  end

  it "interprets non-alphanumeric characters in snake case as word boundaries" do
    expect(@convert.convert_to_class_name("now_camelized_without-hyphen")).to eq("NowCamelizedWithoutHyphen")
  end

  it "interprets underscore" do
    expect(@convert.convert_to_class_name("_remove_leading_underscore")).to eq("RemoveLeadingUnderscore")
  end
end
