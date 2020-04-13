#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
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
module SpecHelpers
  module Knife
    def redefine_argv(value)
      Object.send(:remove_const, :ARGV)
      Object.send(:const_set, :ARGV, value)
    end

    def with_argv(*argv)
      original_argv = ARGV
      redefine_argv(argv.flatten)
      begin
        yield
      ensure
        redefine_argv(original_argv)
      end
    end
  end
end
