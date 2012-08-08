class ApplicationController < ActionController::Base

  include Chef::Mixin::Checksum

  before_filter :load_environments

  # Check if the user is logged in and if the user still exists
  def login_required
   if session[:user]
     begin
       load_session_user
     rescue
       logout_and_redirect_to_login
     else
       return session[:user]
     end
   else
     self.store_location
     redirect_to users_login_url, :alert => "You don't have access to that, please login."
   end
  end

  def load_session_user
    Chef::WebUIUser.load(session[:user])
  rescue
    raise NotFound, "Cannot find User #{session[:user]}, maybe it got deleted by an Administrator."
  end

  def cleanup_session
    [:user,:level, :environment].each { |n| session.delete(n) }
  end

  def logout_and_redirect_to_login
    cleanup_session
    @user = Chef::WebUIUser.new
    redirect_to users_login_url, :error => $!
  end

  def require_admin
    raise AdminAccessRequired unless is_admin?
  end

  def is_admin?
    user = Chef::WebUIUser.load(session[:user])
    user.admin?
  end

  #return true if there is only one admin left, false otherwise
  def is_last_admin?
    count = 0
    users = Chef::WebUIUser.list
    users.each do |u, url|
      user = Chef::WebUIUser.load(u)
      if user.admin
        count = count + 1
        return false if count == 2
      end
    end
    true
  end

  #whether or not the user should be able to edit a user's admin status
  def can_edit_admin?
    return false unless is_admin? && !is_last_admin?
    true
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.url
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    loc = session[:return_to] || default
    session[:return_to] = nil
    redirect_to loc
  end

  def load_environments
    @environments = Chef::Environment.list.keys.sort
  end

  # Load a cookbook and return a hash with a list of all the files of a
  # given segment (attributes, recipes, definitions, libraries)
  #
  # === Parameters
  # cookbook_id<String>:: The cookbook to load
  # segment<Symbol>:: :attributes, :recipes, :definitions, :libraries
  #
  # === Returns
  # <Hash>:: A hash consisting of the short name of the file in :name, and the full path
  #   to the file in :file.
  def load_cookbook_segment(cookbook_id, segment)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    cookbook = r.get_rest("cookbooks/#{cookbook_id}")

    raise NotFound unless cookbook

    files_list = segment_files(segment, cookbook)

    files = Hash.new
    files_list.each do |f|
      files[f['name']] = {
        :name => f["name"],
        :file => f["uri"],
      }
    end
    files
  end

  def segment_files(segment, cookbook)
    files_list = nil
    case segment
    when :attributes
      files_list = cookbook["attributes"]
    when :recipes
      files_list = cookbook["recipes"]
    when :definitions
      files_list = cookbook["definitions"]
    when :libraries
      files_list = cookbook["libraries"]
    else
      raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions or :libraries"
    end
    files_list
  end

  def syntax_highlight(file_url)
    Chef::Log.debug("fetching file from '#{file_url}' for highlighting")
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    highlighted_file = nil
    r.fetch(file_url) do |tempfile|
      tokens = CodeRay.scan_file(tempfile.path, :ruby)
      highlighted_file = CodeRay.encode_tokens(tokens, :span)
    end
    highlighted_file
  end

  def show_plain_file(file_url)
    Chef::Log.debug("fetching file from '#{file_url}' for highlighting")
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    r.fetch(file_url) do |tempfile|
      if binary?(tempfile.path)
        return "Binary file not shown"
      elsif ((File.size(tempfile.path) / (1048576)) > 5)
        return "File too large to display"
      else
        return IO.read(tempfile.path)
      end
    end
  end

  def binary?(file)
    s = (File.read(file, File.stat(file).blksize) || "")
    s.empty? || ( s.count( "^ -~", "^\r\n" ).fdiv(s.size) > 0.3 || s.index( "\x00" ))
  end

  def str_to_bool(str)
    str =~ /true/ ? true : false
  end

  #for showing search result
  def determine_name(type, object)
    case type
    when :node, :role, :client, :environment
      object.name
    else
      params[:id]
    end
  end

  def list_available_recipes_for(environment)
    Chef::Environment.load_filtered_recipe_list(environment).sort!
  end

  def format_exception(exception)
    require 'pp'
    pretty_params = StringIO.new
    PP.pp({:request_params => params}, pretty_params)
    "#{exception.class.name}: #{exception.message}\n#{pretty_params.string}\n#{exception.backtrace.join("\n")}"
  end

  def conflict?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /409/
  end

  def forbidden?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /403/
  end

  def not_found?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /404/
  end

  def bad_request?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /400/
  end
end
