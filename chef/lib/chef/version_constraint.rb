# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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
require 'chef/version_class'

class Chef
  class VersionConstraint
    STANDARD_OPS = %w(< > <= >=)
    OPS = %w(< > = <= >= ~>)
    PATTERN = /^(#{OPS.join('|')}) (.+)$/

    def initialize(str=">= 0.0.0")
      s = str.to_s
      s = ">= 0.0.0" if s.empty?
      parse(s)
    end

    def include?(v)
      version = if v.respond_to? :version # a CookbookVersion-like object
                  Chef::Version.new(v.version.to_s)
                else
                  Chef::Version.new(v.to_s)
                end
     do_op(version)
    end

    def do_op(other_version)
      if STANDARD_OPS.include? @op
        other_version.send(@op.to_sym, @version)
      elsif @op == '='
        other_version == @version
      elsif @op == '~>'
        if @missing_patch_level
          (other_version.major == @version.major &&
           other_version.minor >= @version.minor)
        else
          (other_version.major == @version.major &&
           other_version.minor == @version.minor &&
           other_version.patch >= @version.patch)
        end
      else                      # should never happen
        raise "bad op #{@op}"
      end
    end

    def inspect
      "(#{@op} #{@version})"
    end

    def to_s
      "#{@op} #{@version}"
    end


    private

    def parse(str)
      @missing_patch_level = false
      if str.index(" ").nil? && str =~ /^[0-9]/
        # try for lone version, implied '='
        @version = Chef::Version.new(str)
        @op = "="
      elsif PATTERN.match str
        @op = $1
        raw_version = $2
        @version = Chef::Version.new(raw_version)
        if raw_version.split('.').count == 2
          @missing_patch_level = true
        end
      else
        raise Chef::Exceptions::InvalidVersionConstraint.new "'#{str}'"
      end
    end

  end
end
