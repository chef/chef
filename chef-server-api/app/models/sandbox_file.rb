#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/sandbox'
require 'chef/exceptions'
require 'chef/checksum_cache'

module ChefServerApi
  class SandboxFile
    attr_reader :sandbox_id
    attr_reader :expected_checksum
    attr_reader :error

    def initialize(input, params={})
      @input = input
      @sandbox_id = params[:sandbox_id]
      @expected_checksum = params[:checksum]
      @sandbox_loaded = false
      @error = nil
    end

    def resource_params
      {:sandbox_id => sandbox_id, :checksum => expected_checksum}
    end

    def sandbox
      unless @sandbox_loaded
        load_sandbox
        @sandbox_loaded = true
      end
      @sandbox
    end

    def commit_to(destination_file_path)
      if @input.respond_to?(:path) && @input.path
        commit_tempfile_to(destination_file_path)
      else
        commit_stringio_to(destination_file_path)
      end
    end

    def actual_checksum
      @actual_checksum ||= begin
        @input.rewind
        Chef::ChecksumCache.instance.generate_md5_checksum(@input)
      end
    end

    def invalid_file?
      if expected_checksum != actual_checksum
        @error = "Uploaded file is invalid: expected a md5 sum '#{expected_checksum}', but it was '#{actual_checksum}'"
      else
        false
      end
    end

    def invalid_params?
      if @sandbox_id.nil?
        @error = "Cannot upload file with checksum '#{expected_checksum}': you must provide a sandbox_id"
      elsif @expected_checksum.nil?
        @error = "Cannot upload file to sandbox '#{sandbox_id}': you must provide the file's checksum"
      else
        false
      end
    end

    def invalid_sandbox?
      if sandbox.nil?
        @error = "Cannot find sandbox with id '#{sandbox_id}' in the database"
      elsif !sandbox.member?(@expected_checksum)
        @error = "Cannot upload file: checksum '#{expected_checksum}' isn't a part of sandbox '#{sandbox_id}'"
      else
        false
      end
    end

    private

    def load_sandbox
      @sandbox = Chef::Sandbox.cdb_load(@sandbox_id)
    rescue Chef::Exceptions::CouchDBNotFound
      @sandbox = nil
    end 

    def commit_stringio_to(destination_file_path)
      Tempfile.open("sandbox") do |src|
        @input.rewind
        while chunk = @input.read(8184)
          src.write(chunk)
        end
        src.close
        Chef::Log.info("upload_checksum: move #{src.path} to #{destination_file_path}")
        FileUtils.mv(src.path, destination_file_path)
      end
    end

    def commit_tempfile_to(destination_file_path)
      Chef::Log.debug("Sandbox file provided as tempfile: #{@input.inspect}")
      Chef::Log.info("upload_checksum: move #{@input.path} to #{destination_file_path}")
      FileUtils.mv(@input.path, destination_file_path)
    end

  end
  
end
