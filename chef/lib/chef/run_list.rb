#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

class Chef
  class RunList
    include Enumerable

    attr_reader :recipes, :roles, :run_list

    def initialize
      @run_list = Array.new
      @recipes = Array.new
      @roles = Array.new
    end

    def <<(item)
      type, entry, fentry = parse_entry(item)
      case type
      when 'recipe'
        @recipes << entry unless @recipes.include?(entry)
      when 'role'
        @roles << entry unless @roles.include?(entry)
      end
      @run_list << fentry unless @run_list.include?(fentry)
      self
    end

    def [](pos)
      @run_list[pos]
    end

    def []=(pos, item)
      type, entry, fentry = parse_entry(item)
      @run_list[pos] = fentry 
    end

    def each(&block)
      @run_list.each { |i| block.call(i) }
    end

    def include?(item)
      type, entry, fentry = parse_entry(item)
      @run_list.include?(fentry)
    end

    def reset(*args)
      @run_list = Array.new
      @recipes = Array.new
      @roles = Array.new
      args.flatten.each do |item|
        self << item
      end
      self
    end

    def parse_entry(entry)
      case entry 
      when /^(.+)\[(.+)\]$/
        [ $1, $2, entry ]
      else
        [ 'recipe', entry, "recipe[#{entry}]" ]
      end
    end

  end
end

