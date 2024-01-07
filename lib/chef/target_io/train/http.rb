# require_relative "../mixin/which"

module TargetIO
  module TrainCompat
    class HTTP
      def initialize(url)
        @url = url
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

      def request(method, path, headers = {}, data = false)
        cmd = nil
        SUPPORTED_COMMANDS.each do |command_name|
          executable = which(command_name).chop
          next if !executable || executable.empty?

          url = path.start_with?('http') ? path : File.join(@url, path)
          cmd = self.send(command_name.to_sym, executable, method.to_s.upcase, url, headers, data)
          break
        end

        raise "Target needs one of #{SUPPORTED_COMMANDS.join('/')} for HTTP requests to work" unless cmd

        connection = Chef.run_context&.transport_connection
        connection.run_command(cmd).stdout
      end

      SUPPORTED_COMMANDS = %w[curl wget]

      # Sending data is not yet supported
      def curl(cmd, method, url, headers, _data)
        cmd += headers.map { |name, value| " --header '#{name}: #{value}'"}.join
        cmd += " --request #{method} "
        cmd += url
      end

      # Sending data is not yet supported
      def wget(cmd, method, url, headers, _data)
        cmd += headers.map { |name, value| " --header '#{name}: #{value}'"}.join
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
