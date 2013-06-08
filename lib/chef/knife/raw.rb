require 'chef/knife'

class Chef
  class Knife
    class Raw < Chef::Knife
      banner "knife raw REQUEST_PATH"

      deps do
        require 'json'
        require 'chef/rest'
        require 'chef/config'
        require 'chef/chef_fs/raw_request'
      end

      option :method,
        :long => '--method METHOD',
        :short => '-m METHOD',
        :default => "GET",
        :description => "Request method (GET, POST, PUT or DELETE).  Default: GET"

      option :pretty,
        :long => '--[no-]pretty',
        :boolean => true,
        :default => true,
        :description => "Pretty-print JSON output.  Default: true"

      option :input,
        :long => '--input FILE',
        :short => '-i FILE',
        :description => "Name of file to use for PUT or POST"

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must provide the path you want to hit on the server")
          exit(1)
        elsif name_args.length > 1
          show_usage
          ui.fatal("Only one path accepted for knife raw")
          exit(1)
        end

        path = name_args[0]
        data = false
        if config[:input]
          data = IO.read(config[:input])
        end
        chef_rest = Chef::REST.new(Chef::Config[:chef_server_url])
        begin
          output Chef::ChefFS::RawRequest.api_request(chef_rest, config[:method].to_sym, chef_rest.create_url(name_args[0]), {}, data)
        rescue Timeout::Error => e
          ui.error "Server timeout"
          exit 1
        rescue Net::HTTPServerException => e
          ui.error "Server responded with error #{e.response.code} \"#{e.response.message}\""
          ui.error "Error Body: #{e.response.body}" if e.response.body && e.response.body != ''
          exit 1
        end
      end

    end # class Raw
  end
end

