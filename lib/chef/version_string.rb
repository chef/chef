# Copyright:: Copyright 2017, Noah Kantrowitz
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
  # String-like object for version strings.
  #
  # @since 13.2
  # @api internal
  class VersionString < String
    # Parsed version object for the string.
    # @return [Gem::Version]
    attr_reader :parsed_version

    # Create a new VersionString from an input String.
    #
    # @param val [String] Version string to parse.
    def initialize(val)
      super
      @parsed_version = ::Gem::Version.create(self)
    end

    # @!group Compat wrappers for String

    # Compat wrapper for + to behave like a normal String.
    #
    # @param other [String]
    # @return [String]
    def +(other)
      to_s + other
    end

    # Compat wrapper for * to behave like a normal String.
    #
    # @param other [Integer]
    # @return [String]
    def *(other)
      to_s * other
    end

    # @!group Comparison operators

    # Compare a VersionString to an object. If compared to another VersionString
    # then sort like `Gem::Version`, otherwise try to treat the other object as
    # a version but fall back to normal string comparison.
    #
    # @param other [Object]
    # @return [Integer]
    def <=>(other)
      other_ver = case other
                  when VersionString
                    other.parsed_version
                  else
                    begin
                      Gem::Version.create(other.to_s)
                    rescue ArgumentError
                      # Comparing to a string that isn't a version.
                      return super
                    end
                  end
      parsed_version <=> other_ver
    end

    # Compat wrapper for == based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      (self <=> other) == 0
    end

    # Compat wrapper for != based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def !=(other)
      (self <=> other) != 0
    end

    # Compat wrapper for < based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def <(other)
      (self <=> other) < 0
    end

    # Compat wrapper for <= based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def <=(other)
      (self <=> other) < 1
    end

    # Compat wrapper for > based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def >(other)
      (self <=> other) > 0
    end

    # Compat wrapper for >= based on <=>.
    #
    # @param other [Object]
    # @return [Boolean]
    def >=(other)
      (self <=> other) > -1
    end

    # @!group Matching operators

    # Matching operator to support checking against a requirement string.
    #
    # @param other [Regexp, String]
    # @return [Boolean]
    # @example Match against a Regexp
    #   Chef::VersionString.new('1.0.0') =~ /^1/
    # @example Match against a requirement
    #   Chef::VersionString.new('1.0.0') =~ '~> 1.0'
    def =~(other)
      case other
      when Regexp
        super
      else
        Gem::Requirement.create(other) =~ parsed_version
      end
    end

  end
end
