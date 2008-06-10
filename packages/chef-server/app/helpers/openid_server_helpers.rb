module Merb
  module OpenidServerHelper

    def url_for_user
      url(:openid_node, :username => session[:username])
    end

  end
end
