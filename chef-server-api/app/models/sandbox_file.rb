
##
# Sandboxes upload checksum
##
# sandbox_guid = params[:sandbox_id]
# checksum = params[:checksum]
# 
# existing_sandbox = Chef::Sandbox.cdb_load(sandbox_guid)
# raise NotFound, "cannot find sandbox with guid #{sandbox_guid}" unless existing_sandbox  
# raise NotFound, "checksum #{checksum} isn't a part of sandbox #{sandbox_guid}" unless existing_sandbox.checksums.member?(checksum)
# 
# Tempfile.open("sandbox") do |src|
#   rack_input = self.request.env["rack.input"]
#   Chef::Log.debug("Processing rack input: #{rack_input.inspect}")
#   
#   src.write(rack_input.string) 
#   src.close
# 
#   observed_checksum = Chef::Cache::Checksum.generate_md5_checksum_for_file(src.path)
#   
#   raise BadRequest, "Checksum did not match: expected #{checksum}, observed #{observed_checksum}" unless observed_checksum == checksum
# 
#   dest = sandbox_checksum_location(sandbox_guid, checksum)
#   Chef::Log.info("upload_checksum: move #{src} to #{dest}")
#   FileUtils.mv(src.path, dest)
# end
# 
# url = absolute_url(:sandbox_checksum, :sandbox_id => sandbox_guid, :checksum => checksum)
# result = { 'uri' => url }
# display result
# 

require 'chef/sandbox'
require 'chef/exceptions'
require 'chef/cache/checksum'

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
        Chef::Cache::Checksum.instance.generate_md5_checksum(@input)
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
        src.write(@input.string) 
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