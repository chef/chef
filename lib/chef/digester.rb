#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

autoload :OpenSSL, "openssl"
autoload :Digest, "digest"
require "singleton" unless defined?(Singleton)

class Chef
  class Digester
    include Singleton

    def self.checksum_for_file(*args)
      instance.checksum_for_file(*args)
    end

    def validate_checksum(*args)
      self.class.validate_checksum(*args)
    end

    def checksum_for_file(file)
      generate_checksum(file)
    end

    def generate_checksum(file)
      if file.is_a?(StringIO)
        checksum_io(file, OpenSSL::Digest.new("SHA256"))
      else
        checksum_file(file, OpenSSL::Digest.new("SHA256"))
      end
    end

    def self.generate_md5_checksum_for_file(*args)
      instance.generate_md5_checksum_for_file(*args)
    end

    def generate_md5_checksum_for_file(file)
      checksum_file(file, ::Digest::MD5.new)
    end

    def generate_md5_checksum(io)
      checksum_io(io, ::Digest::MD5.new)
    end

    private

    def checksum_file(file, digest)
      File.open(file, "rb") { |f| checksum_io(f, digest) }
    end

    def checksum_io(io, digest)
      while chunk = io.read(1024 * 8)
        digest.update(chunk)
      end
      digest.hexdigest
    end

  end
end
