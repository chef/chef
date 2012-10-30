#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

# ensure data is written and read in binary mode
# stops "dump format error for symbol(0x75)" errors
module Moneta
  class BasicFile

    def store(key, value, options = {})
      ensure_directory_created(::File.dirname(path(key)))
      ::File.open(path(key), "wb") do |file|
        if @expires
          data = {:value => value}
          if options[:expires_in]
            data[:expires_at] = Time.now + options[:expires_in]
          end
          contents = Marshal.dump(data)
        else
          contents = Marshal.dump(value)
        end
        file.puts(contents)
      end
    end

    def raw_get(key)
      if ::File.respond_to?(:binread)
        data = ::File.binread(path(key))
      else
        data = ::File.open(path(key),"rb") { |f| f.read }
      end
      Marshal.load(data)
    end

  end
end
