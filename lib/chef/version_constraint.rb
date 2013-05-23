# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright 2010-2011 Opscode, Inc.
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
    DEFAULT_CONSTRAINT = ">= 0.0.0"
    STANDARD_OPS = %w(< > <= >=)
    OPS = %w(< > = <= >= ~>)
    PATTERN = /^(#{OPS.join('|')}) (.+)$/
    VERSION_CLASS = Chef::Version

    attr_reader :op, :version

    def initialize(constraint_spec=DEFAULT_CONSTRAINT)
      case constraint_spec
      when nil
        parse(DEFAULT_CONSTRAINT)
      when Array
        parse_from_array(constraint_spec)
      when String
        parse(constraint_spec)
      else
        msg = "VersionConstraint should be created from a String. You gave: #{constraint_spec.inspect}"
        raise Chef::Exceptions::InvalidVersionConstraint, msg
      end
    end

    def include?(v)
      version = if v.respond_to? :version # a CookbookVersion-like object
                  self.class::VERSION_CLASS.new(v.version.to_s)
                else
                  self.class::VERSION_CLASS.new(v.to_s)
                end
     do_op(version)
    end

    def inspect
      "(#{@op} #{@version})"
    end

    def to_s
      "#{@op} #{@version}"
    end

    def eql?(o)
      o.class == self.class && @op == o.op && @version == o.version
    end
    alias_method :==, :eql?

    private

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

    def parse_from_array(constraint_spec)
      if constraint_spec.empty?
        parse(DEFAULT_CONSTRAINT)
      elsif constraint_spec.size == 1
        parse(constraint_spec.first)
      else
        msg = "only one version constraint operation is supported, but you gave #{constraint_spec.size} "
        msg << "['#{constraint_spec.join(', ')}']"
        raise Chef::Exceptions::InvalidVersionConstraint, msg
      end
    end

    def parse(str)
      @missing_patch_level = false
      if str.index(" ").nil? && str =~ /^[0-9]/
        # try for lone version, implied '='
        @version = self.class::VERSION_CLASS.new(str)
        @op = "="
      elsif PATTERN.match str
        @op = $1
        raw_version = $2
        @version = self.class::VERSION_CLASS.new(raw_version)
        if raw_version.split('.').size <= 2
          @missing_patch_level = true
        end
      else
        raise Chef::Exceptions::InvalidVersionConstraint, "'#{str}'"
      end
    end

  end
end
