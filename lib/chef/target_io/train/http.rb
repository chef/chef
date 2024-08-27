# require_relative "../mixin/which"

module TargetIO
  module TrainCompat
    class HTTP
      attr_reader :last_response

      def initialize(url, options = {})
        @url = url.is_a?(URI) ? url.to_s : url
        @options = options
        @last_response = ""
      end

      # Send an HTTP HEAD request to the path
      #
      # === Parameters
      # path:: path part of the request URL
      def head(path, headers = {})
        request(:HEAD, path, headers)
      end

      # Send an HTTP GET request to the path
      #
      # === Parameters
      # path:: The path to GET
      def get(path, headers = {})
        request(:GET, path, headers)
      end

      # Send an HTTP PUT request to the path
      #
      # === Parameters
      # path:: path part of the request URL
      def put(path, json, headers = {})
        request(:PUT, path, headers, json)
      end

      # Send an HTTP POST request to the path
      #
      # === Parameters
      # path:: path part of the request URL
      def post(path, json, headers = {})
        request(:POST, path, headers, json)
      end

      # Send an HTTP DELETE request to the path
      #
      # === Parameters
      # path:: path part of the request URL
      def delete(path, headers = {})
        request(:DELETE, path, headers)
      end

      # Used inside Chef::Provider::RemoteFile::HTTPS
      def streaming_request(path, headers = {}, tempfile = nil)
        content = get(path, headers)
        @last_response = content

        tempfile.write(content)
        tempfile.close

        tempfile
      end

      def request(method, path, headers = {}, data = false)
        cmd = nil
        path = path.is_a?(URI) ? path.to_s : path
        headers.merge!(@options[:headers] || {})

        SUPPORTED_COMMANDS.each do |command_name|
          executable = which(command_name).chop
          next if !executable || executable.empty?

          # There are different ways to call (constructor, argument, combination of both)
          full_url = if path.start_with?("http")
                       path
                     elsif path.empty? || @url.end_with?(path)
                       @url
                     else
                       File.join(@url, path)
                     end

          cmd = send(command_name.to_sym, executable, method.to_s.upcase, full_url, headers, data)
          break
        end

        raise "Target needs one of #{SUPPORTED_COMMANDS.join("/")} for HTTP requests to work" unless cmd

        connection = Chef.run_context&.transport_connection
        connection.run_command(cmd).stdout
      end

      SUPPORTED_COMMANDS = %w{curl wget}.freeze

      # Sending data is not yet supported
      def curl(cmd, method, url, headers, _data)
        cmd += headers.map { |name, value| " --header '#{name}: #{value}'" }.join
        cmd += " --request #{method} "
        cmd += url
      end

      # Sending data is not yet supported
      def wget(cmd, method, url, headers, _data)
        cmd += headers.map { |name, value| " --header '#{name}: #{value}'" }.join
        cmd += " --method #{method}"
        cmd += " --output-document=- "
        cmd += url
      end

      # extend Chef::Mixin::Which
      def which(cmd)
        connection = Chef.run_context&.transport_connection
        connection.run_command("which #{cmd}").stdout
      end
    end
  end
end
