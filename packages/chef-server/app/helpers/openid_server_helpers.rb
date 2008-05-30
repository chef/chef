module Merb
  module OpenidServerHelper

    def url_for_user
      url(:openid_user, :username => session[:username])
    end

  end
end
