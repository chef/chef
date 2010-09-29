#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require 'chef/log'
require 'chef/config'
require 'chef/mixin/convert_to_class_name'
require 'singleton'
require 'moneta'

class Chef 
  class ChecksumCache
    include Chef::Mixin::ConvertToClassName
    include ::Singleton
    
    attr_reader :moneta
    
    def initialize(*args)
      self.reset!(*args)
    end
    
    def reset!(backend=nil, options=nil)
      backend ||= Chef::Config[:cache_type]
      options ||= Chef::Config[:cache_options]
      
      begin
        require "moneta/#{convert_to_snake_case(backend, 'Moneta')}"
      rescue LoadError => e
        Chef::Log.fatal("Could not load Moneta back end #{backend.inspect}")
        raise e
      end
     
      @moneta = Moneta.const_get(backend).new(options)
    end

    def self.checksum_for_file(*args)
      instance.checksum_for_file(*args)
    end

    def checksum_for_file(file, key=nil)
      key ||= generate_key(file)
      fstat = File.stat(file)
      lookup_checksum(key, fstat) || generate_checksum(key, file, fstat)
    end

    def lookup_checksum(key, fstat)
      cached = @moneta.fetch(key)
      if cached && file_unchanged?(cached, fstat)
        cached["checksum"]
      else
        nil
      end
    end

    def generate_checksum(key, file, fstat)
      checksum = checksum_file(file, Digest::SHA256.new)
      moneta.store(key, {"mtime" => fstat.mtime.to_f, "checksum" => checksum})
      checksum
    end

    def generate_key(file, group="chef")
      "#{group}-file-#{file.gsub(/(#{File::SEPARATOR}|\.)/, '-')}"
    end

    def self.generate_md5_checksum_for_file(*args)
      instance.generate_md5_checksum_for_file(*args)
    end

    def generate_md5_checksum_for_file(file)
      checksum_file(file, Digest::MD5.new)
    end

    def generate_md5_checksum(io)
      checksum_io(io, Digest::MD5.new)
    end

    private

    def file_unchanged?(cached, fstat)
      cached["mtime"].to_f == fstat.mtime.to_f
    end

    def checksum_file(file, digest)
      File.open(file) { |f| checksum_io(f, digest) }
    end

    def checksum_io(io, digest)
      while chunk = io.read(1024 * 8)
        digest.update(chunk)
      end
      digest.hexdigest
    end

  end
end

module Moneta
  module Defaults
    def default
      nil
    end
  end
end
