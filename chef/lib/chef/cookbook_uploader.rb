require 'rest_client'
require 'chef/cookbook_loader'
require 'chef/cache/checksum'
require 'chef/sandbox'
require 'chef/cookbook_version'
require 'chef/cookbook/syntax_check'
require 'chef/cookbook/file_system_file_vendor'

class Chef
  class CookbookUploader
    class << self

      def upload_cookbook(cookbook)
        Chef::Log.info("Saving #{cookbook.name}")

        rest = Chef::REST.new(Chef::Config[:chef_server_url])

        # Validate the cookbook before staging it or else the syntax checker's
        # cache will not be helpful.
        validate_cookbook(cookbook)
        # create build directory
        tmp_cookbook_dir = create_build_dir(cookbook)

        # create a CookbookLoader that loads a Cookbook from the build directory
        orig_cookbook_path = nil
        build_dir_cookbook = nil
        begin
          orig_cookbook_path = Chef::Config.cookbook_path
          Chef::Config.cookbook_path = tmp_cookbook_dir
          build_dir_cookbook = Chef::CookbookLoader.new[cookbook.name]
          Chef::Log.debug("Staged cookbook manifest:\n#{JSON.pretty_generate(build_dir_cookbook)}")
        ensure
          Chef::Config.cookbook_path = orig_cookbook_path
        end

        # generate checksums of cookbook files and create a sandbox
        checksum_files = build_dir_cookbook.checksums
        checksums = checksum_files.inject({}){|memo,elt| memo[elt.first]=nil ; memo}
        new_sandbox = catch_auth_exceptions{ rest.post_rest("/sandboxes", { :checksums => checksums }) }

        Chef::Log.info("Uploading files")
        # upload the new checksums and commit the sandbox
        new_sandbox['checksums'].each do |checksum, info|
          if info['needs_upload'] == true
            Chef::Log.info("Uploading #{checksum_files[checksum]} (checksum hex = #{checksum}) to #{info['url']}")

            # Checksum is the hexadecimal representation of the md5,
            # but we need the base64 encoding for the content-md5
            # header
            checksum64 = Base64.encode64([checksum].pack("H*")).strip
            timestamp = Time.now.utc.iso8601
            file_contents = File.read(checksum_files[checksum])
            # TODO - 5/28/2010, cw: make signing and sending the request streaming
            sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(
                                                                               :http_method => :put,
                                                                               :path        => URI.parse(info['url']).path,
                                                                               :body        => file_contents,
                                                                               :timestamp   => timestamp,
                                                                               :user_id     => rest.client_name
                                                                               )
            headers = { 'content-type' => 'application/x-binary', 'content-md5' => checksum64, :accept => 'application/json' }
            headers.merge!(sign_obj.sign(OpenSSL::PKey::RSA.new(rest.signing_key)))
            begin
              RestClient::Request.execute(:method => :put, :url => info['url'], :headers => headers, :payload => file_contents)
            rescue RestClient::RequestFailed => e
              Chef::Log.error("Upload failed: #{e.message}\n#{e.response.body}")
              raise
            end
          else
            Chef::Log.debug("#{checksum_files[checksum]} has not changed")
          end
        end
        sandbox_url = new_sandbox['uri']
        Chef::Log.debug("Committing sandbox")
        # Retry if S3 is claims a checksum doesn't exist (the eventual
        # in eventual consistency)
        retries = 0
        begin
          catch_auth_exceptions{ rest.put_rest(sandbox_url, {:is_completed => true}) }
        rescue Net::HTTPServerException => e
          if e.message =~ /^400/ && (retries += 1) <= 5
            sleep 2
            retry
          else
            raise
          end
        end

        # files are uploaded, so save the manifest
        catch_auth_exceptions{ build_dir_cookbook.save }

        Chef::Log.info("Upload complete!")
        Chef::Log.debug("Removing local staging directory at #{tmp_cookbook_dir}")
        FileUtils.rm_rf tmp_cookbook_dir
      end

      def create_build_dir(cookbook)
        tmp_cookbook_path = Tempfile.new("chef-#{cookbook.name}-build")
        tmp_cookbook_path.close
        tmp_cookbook_dir = tmp_cookbook_path.path
        File.unlink(tmp_cookbook_dir)
        FileUtils.mkdir_p(tmp_cookbook_dir)

        Chef::Log.debug("Staging at #{tmp_cookbook_dir}")

        checksums_to_on_disk_paths = cookbook.checksums

        Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
          cookbook.manifest[segment].each do |manifest_record|
            path_in_cookbook = manifest_record[:path]
            on_disk_path = checksums_to_on_disk_paths[manifest_record[:checksum]]
            dest = File.join(tmp_cookbook_dir, cookbook.name.to_s, path_in_cookbook)
            FileUtils.mkdir_p(File.dirname(dest))
            Chef::Log.debug("Staging #{on_disk_path} to #{dest}")
            FileUtils.cp(on_disk_path, dest)
          end
        end

        # First, generate metadata
        Chef::Log.debug("Generating metadata")
        kcm = Chef::Knife::CookbookMetadata.new
        kcm.config[:cookbook_path] = [ tmp_cookbook_dir ]
        kcm.name_args = [ cookbook.name.to_s ]
        kcm.run

        tmp_cookbook_dir
      end

      def validate_cookbook(cookbook)
        syntax_checker = Chef::Cookbook::SyntaxCheck.for_cookbook(cookbook.name, @user_cookbook_path)
        Chef::Log.info("Validating ruby files")
        exit(1) unless syntax_checker.validate_ruby_files
        Chef::Log.info("Validating templates")
        exit(1) unless syntax_checker.validate_templates
        Chef::Log.info("Syntax OK")
        true
      end

      private
      def catch_auth_exceptions
        begin
          yield
        rescue Net::HTTPServerException => e
          case e.response.code
          when "401"
            Chef::Log.fatal "Request failed due to authentication (#{e}), check your client configuration (username, key)"
            exit 18
          else
            raise
          end
        end
      end

    end
  end
end