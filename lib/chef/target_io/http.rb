require 'forwardable'

require_relative "../http/simple"
require_relative "train/http"

module TargetIO
  class HTTP
    extend Forwardable
    def_delegators :@http_class, :get, :head, :patch, :post, :put, :delete

    def initialize(url)
      if ::ChefConfig::Config.target_mode?
        @http_class = TargetIO::TrainCompat::HTTP.new(url)
      else
        @http_class = Chef::HTTP::Simple.new(url)
      end
    end
  end
end
