# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright 2013-2016, Onddo Labs, SL.
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

require_relative "../version_class"

# NOTE: this is fairly badly broken for its purpose and should not be used
#       unless it gets fixed.

# this strictly wants x, x.y, or x.y.z version constraints in the target and
# will fail hard if it does not match.  the semantics that we need here is that
# it must always do the best job that it can do and consume as much of the
# offered version as it can.  since we accept arbitrarily parsed strings into
# node[:platform_version] out of dozens or potentially hundreds of operating
# systems this parsing code needs to be fixed to never raise.  the Gem::Version
# class is a better model, and in fact it might be a substantially better approach
# to base this class on Gem::Version and then do pre-mangling of things like windows
# version strings via e.g. `.gsub(/R/, '.')`.  the raising behavior of this parser
# however, breaks the ProviderResolver in a not just buggy but a "completely unfit
# for purpose" way.
#
# TL;DR: MUST follow the second part of "Be conservative in what you send,
# be liberal in what you accept"
#
class Chef
  class Version
    class Platform < Chef::Version

      protected

      def parse(str = "")
        @major, @minor, @patch =
          case str.to_s
          when /^(\d+)\.(\d+)\.(\d+)$/
            [ $1.to_i, $2.to_i, $3.to_i ]
          when /^(\d+)\.(\d+)$/
            [ $1.to_i, $2.to_i, 0 ]
          when /^(\d+)$/
            [ $1.to_i, 0, 0 ]
          when /^(\d+).(\d+)-[a-z]+\d?(-p(\d+))?$/i # Match FreeBSD
            [ $1.to_i, $2.to_i, ($4 ? $4.to_i : 0)]
          else
            msg = "'#{str}' does not match 'x.y.z', 'x.y' or 'x'"
            raise Chef::Exceptions::InvalidPlatformVersion.new( msg )
          end
      end

    end
  end
end
