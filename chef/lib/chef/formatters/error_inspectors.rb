require 'chef/formatters/api_error_inspector'
require 'chef/formatters/compile_error_inspector'

class Chef
  module Formatters

    # == ErrorInspectors
    # Error inspectors wrap exceptions and contextual information. They
    # generate diagnostic messages about possible causes of the error for user
    # consumption.
    module ErrorInspectors
    end
  end
end
