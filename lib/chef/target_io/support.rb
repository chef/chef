require "tempfile" unless defined?(::Tempfile)

module TargetIO
  module Support
    # "sudo" based connections need a staging area for file reading/writing
    def read_file(filename)
      accessible_file = filename

      if sudo?
        accessible_file = staging_file(filename)
        ::TargetIO::FileUtils.cp(filename, accessible_file)
      end

      content = transport_connection.file(accessible_file).content

      clean_staging(accessible_file) if sudo?

      content
    end

    def write_file(remote_file, content)
      tempfile = ::Tempfile.new
      tempfile.write(tempfile, content)
      tempfile.close

      upload(tempfile.path, remote_file)
      tempfile.unlink

      remote_file
    end

    def upload(local_file, remote_file)
      accessible_file = remote_file
      accessible_file = staging_file(remote_file) if sudo?

      transport_connection.upload(local_file, accessible_file)

      if sudo?
        ::TargetIO::FileUtils.mv(accessible_file, remote_file)
        clean_staging(accessible_file)
      end
    end

    def staging_file(filename)
      staging_dir = ::TargetIO::Dir.mktmpdir(filename)
      ::File.join(staging_dir, ::File.basename(filename))
    end

    def clean_staging(filename)
      ::TargetIO::FileUtils.rm(filename)

      staging_dir = ::File.dirname(filename)
      ::TargetIO::FileUtils.rmdir(staging_dir)
    rescue Errno::ENOENT
    end

    def run_command(cmd)
      transport_connection.run_command(cmd)
    end

    def sudo?
      transport_connection.transport_options[:sudo]
    end

    def remote_user
      transport_connection.transport_options[:user]
    end

    def transport_connection
      Chef.run_context&.transport_connection
    end
  end
end
