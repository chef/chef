# Author:: Seth Falcon (<seth@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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

class Chef
  class Version
    include Comparable
    attr_reader :major, :minor, :patch

    def initialize(str = "")
      parse(str)
    end

    def inspect
      "#{@major}.#{@minor}.#{@patch}"
    end

    def to_s
      "#{@major}.#{@minor}.#{@patch}"
    end

    def <=>(other)
      [:major, :minor, :patch].each do |method|
        version = send(method)
        begin
          ans = (version <=> other.send(method))
        rescue NoMethodError # if the other thing isn't a version object, return nil
          return nil
        end
        return ans unless ans == 0
      end
      0
    end

    def hash
      # Didn't put any thought or research into this, probably can be
      # done better
      to_s.hash
    end

    # For hash
    def eql?(other)
      other.is_a?(Version) && self == other
    end

    protected

    def parse(str = "")
      @major, @minor, @patch =
        case str.to_s
        when /^(\d+)\.(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, $3.to_i ]
        when /^(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, 0 ]
        else
          msg = "'#{str}' does not match 'x.y.z' or 'x.y'"
          raise Chef::Exceptions::InvalidCookbookVersion.new( msg )
        end
    end

  end
end
