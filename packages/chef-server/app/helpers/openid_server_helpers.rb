module Merb
  module OpenidServerHelper

    def url_for_user
      url :controller => 'user', :action => session[:username]
    end

  end
end
