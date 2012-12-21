
require 'set'
require 'rest_client'
require 'chef/exceptions'
require 'chef/knife/cookbook_metadata'
require 'chef/digester'
require 'chef/cookbook_version'
require 'chef/cookbook/syntax_check'
require 'chef/cookbook/file_system_file_vendor'
require 'chef/sandbox'

class Chef
  class CookbookUploader

    def self.work_queue
      @work_queue ||= Queue.new
    end

    def self.setup_worker_threads
      @worker_threads ||= begin
        work_queue
        (1...10).map do
          Thread.new do
            loop do
              work_queue.pop.call
            end
          end
        end
      end
    end

    attr_reader :cookbooks
    attr_reader :path
    attr_reader :opts
    attr_reader :rest

    # Creates a new CookbookUploader.
    # ===Arguments:
    # * cookbooks::: A Chef::CookbookVersion or array of them describing the
    #                cookbook(s) to be uploaded
    # * path::: A String or Array of Strings representing the base paths to the
    #           cookbook repositories.
    # * opts::: (optional) An options Hash
    # ===Options:
    # * :force  indicates that the uploader should set the force option when
    #           uploading the cookbook. This allows frozen CookbookVersion
    #           documents on the server to be overwritten (otherwise a 409 is
    #           returned by the server)
    # * :rest   A Chef::REST object that you have configured the way you like it.
    #           If you don't provide this, one will be created using the values
    #           in Chef::Config.
    def initialize(cookbooks, path, opts={})
      @path, @opts = path, opts
      @cookbooks = Array(cookbooks)
      @rest = opts[:rest] || Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def upload_cookbooks
      Thread.abort_on_exception = true

      # Syntax Check
      validate_cookbooks
      # generate checksums of cookbook files and create a sandbox
      checksum_files = {}
      cookbooks.each do |cb|
        Chef::Log.info("Saving #{cb.name}")
        checksum_files.merge!(cb.checksums)
      end

      checksums = checksum_files.inject({}){|memo,elt| memo[elt.first]=nil ; memo}
      new_sandbox = rest.post_rest("sandboxes", { :checksums => checksums })

      Chef::Log.info("Uploading files")

      self.class.setup_worker_threads

      checksums_to_upload = Set.new

      # upload the new checksums and commit the sandbox
      new_sandbox['checksums'].each do |checksum, info|
        if info['needs_upload'] == true
          checksums_to_upload << checksum
          Chef::Log.info("Uploading #{checksum_files[checksum]} (checksum hex = #{checksum}) to #{info['url']}")
          self.class.work_queue << uploader_function_for(checksum_files[checksum], checksum, info['url'], checksums_to_upload)
        else
          Chef::Log.debug("#{checksum_files[checksum]} has not changed")
        end
      end

      until checksums_to_upload.empty?
        sleep 0.1
      end

      sandbox_url = new_sandbox['uri']
      Chef::Log.debug("Committing sandbox")
      # Retry if S3 is claims a checksum doesn't exist (the eventual
      # in eventual consistency)
      retries = 0
      begin
        rest.put_rest(sandbox_url, {:is_completed => true})
      rescue Net::HTTPServerException => e
        if e.message =~ /^400/ && (retries += 1) <= 5
          sleep 2
          retry
        else
          raise
        end
      end

      # files are uploaded, so save the manifest
      cookbooks.each do |cb|
        save_url = opts[:force] ? cb.force_save_url : cb.save_url
        rest.put_rest(save_url, cb)
      end

      Chef::Log.info("Upload complete!")
    end

    def worker_thread(work_queue)
    end

    def uploader_function_for(file, checksum, url, checksums_to_upload)
      lambda do
        # Checksum is the hexadecimal representation of the md5,
        # but we need the base64 encoding for the content-md5
        # header
        checksum64 = Base64.encode64([checksum].pack("H*")).strip
        timestamp = Time.now.utc.iso8601
        file_contents = File.open(file, "rb") {|f| f.read}
        # TODO - 5/28/2010, cw: make signing and sending the request streaming
        sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(
                                                                           :http_method => :put,
                                                                           :path        => URI.parse(url).path,
                                                                           :body        => file_contents,
                                                                           :timestamp   => timestamp,
                                                                           :user_id     => rest.client_name
                                                                           )
        headers = { 'content-type' => 'application/x-binary', 'content-md5' => checksum64, :accept => 'application/json' }
        headers.merge!(sign_obj.sign(OpenSSL::PKey::RSA.new(rest.signing_key)))

        begin
          RestClient::Resource.new(url, :headers=>headers, :timeout=>1800, :open_timeout=>1800).put(file_contents)
          checksums_to_upload.delete(checksum)
        rescue RestClient::Exception => e
          Chef::Knife.ui.error("Failed to upload #@cookbook : #{e.message}\n#{e.response.body}")
          raise
        end
      end
    end

    def validate_cookbooks
      cookbooks.each do |cb|
        syntax_checker = Chef::Cookbook::SyntaxCheck.for_cookbook(cb.name, @user_cookbook_path)
        Chef::Log.info("Validating ruby files")
        exit(1) unless syntax_checker.validate_ruby_files
        Chef::Log.info("Validating templates")
        exit(1) unless syntax_checker.validate_templates
        Chef::Log.info("Syntax OK")
        true
      end
    end

  end
end
