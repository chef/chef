#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc
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

  # Null logger implementation that just ignores everything. This is used by
  # classes that are intended to be reused outside of Chef, but need to offer
  # logging functionality when used by other Chef code.
  #
  # It does not define the full interface provided by Logger, just enough to be
  # a reasonable duck type. In particular, methods setting the log level, log
  # device, etc., are not implemented because any code calling those methods
  # probably expected a real logger and not this "fake" one.
  class NullLogger

    def fatal(message, &block)
    end

    def error(message, &block)
    end

    def warn(message, &block)
    end

    def info(message, &block)
    end

    def debug(message, &block)
    end

    def add(severity, message = nil, progname = nil)
    end

    def <<(message)
    end

    def fatal?
      false
    end

    def error?
      false
    end

    def warn?
      false
    end

    def info?
      false
    end

    def debug?
      false
    end

  end
end
