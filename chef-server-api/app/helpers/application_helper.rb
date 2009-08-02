module Merb
  module ChefServerApi
    module ApplicationHelper
      
      # Generate the absolute url for a slice - takes the slice's :path_prefix into account.
      #
      # @param slice_name<Symbol> 
      #   The name of the slice - in identifier_sym format (underscored).
      # @param *args<Array[Symbol,Hash]> 
      #   There are several possibilities regarding arguments:
      #   - when passing a Hash only, the :default route of the current 
      #     slice will be used
      #   - when a Symbol is passed, it's used as the route name
      #   - a Hash with additional params can optionally be passed
      # 
      # @return <String> A uri based on the requested slice.
      #
      # @example absolute_slice_url(:awesome, :format => 'html')
      # @example absolute_slice_url(:forum, :posts, :format => 'xml')          
      def absolute_slice_url(slice_name, *args)
        options  = extract_options_from_args!(args) || {}
        protocol = options.delete(:protocol) || request.protocol
        host     = options.delete(:host) || request.host

        protocol + "://" + host + slice_url(slice_name,*args)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def image_path(*segments)
        public_path_for(:image, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def javascript_path(*segments)
        public_path_for(:javascript, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def stylesheet_path(*segments)
        public_path_for(:stylesheet, *segments)
      end
      
      # Construct a path relative to the public directory
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def public_path_for(type, *segments)
        ::ChefServerApi.public_path_for(type, *segments)
      end
      
      # Construct an app-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the host application, with added segments.
      def app_path_for(type, *segments)
        ::ChefServerApi.app_path_for(type, *segments)
      end
      
      # Construct a slice-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the slice source (Gem), with added segments.
      def slice_path_for(type, *segments)
        ::ChefServerApi.slice_path_for(type, *segments)
      end
      
      def build_tree(name, node, default={}, override={})
        node = Chef::Mixin::DeepMerge.merge(default, node)
        node = Chef::Mixin::DeepMerge.merge(node, override)
        html = "<table id='#{name}' class='tree table'>"
        html << "<tr><th class='first'>Attribute</th><th class='last'>Value</th></tr>"
        count = 0
        parent = 0
        append_tree(name, html, node, count, parent, override)
        html << "</table>"
        html
      end

      def append_tree(name, html, node, count, parent, override)
        node.sort{ |a,b| a[0] <=> b[0] }.each do |key, value|
          to_send = Array.new
          count += 1
          is_parent = false
          local_html = ""
          local_html << "<tr id='#{name}-#{count}' class='collapsed #{name}"
          if parent != 0
            local_html << " child-of-#{name}-#{parent}' style='display: none;'>"
          else
            local_html << "'>"
          end
          local_html << "<td class='table-key'><span toggle='#{name}-#{count}'/>#{key}</td>"
          case value
          when Hash
            is_parent = true 
            local_html << "<td></td>"
            p = count
            to_send << Proc.new { append_tree(name, html, value, count, p, override) }
          when Array
            is_parent = true 
            local_html << "<td></td>"
            as_hash = {}
            value.each_index { |i| as_hash[i] = value[i] }
            p = count
            to_send << Proc.new { append_tree(name, html, as_hash, count, p, override) }
          when String,Symbol
            local_html << "<td><div class='json-attr'>#{value}</div></td>"
          else
            local_html << "<td>#{JSON.pretty_generate(value)}</td>"
          end
          local_html << "</tr>"
          local_html.sub!(/class='collapsed/, 'class=\'collapsed parent') if is_parent
          local_html.sub!(/<span/, "<span class='expander'") if is_parent
          html << local_html
          to_send.each { |s| count = s.call }
          count += to_send.length
        end
        count
      end

      # Recursively build a tree of lists.
      #def build_tree(node)
      #  list = "<dl>"
      #  list << "\n<!-- Beginning of Tree -->"
      #  walk = lambda do |key,value|
      #    case value
      #      when Hash, Array
      #        list << "\n<!-- Beginning of Enumerable obj -->"
      #        list << "\n<dt>#{key}</dt>"
      #        list << "<dd>"
      #        list << "\t<dl>\n"
      #        value.each(&walk)
      #        list << "\t</dl>\n"
      #        list << "</dd>"
      #        list << "\n<!-- End of Enumerable obj -->"
      #        
      #      else
      #        list << "\n<dt>#{key}</dt>"
      #        list << "<dd>#{value}</dd>"
      #    end
      #  end
      #  node.sort{ |a,b| a[0] <=> b[0] }.each(&walk)
      #  list << "</dl>"
      #end

      
      module AuthenticateEvery
        require 'rubygems'
        require 'mixlib/auth/signatureverification'
        require 'extlib'
        
        class << self
          def authenticator
            @authenticator ||= Mixlib::Auth::SignatureVerification.new      
          end
        end


        protected

        # This is the main method to use as a before filter.  
        # It will perform the user lookup, header signing and signature comparison
        # A failed login will result in an Unauthorized exception being raised.
        #
        # ====Parameters
        #
        def authenticate_every
          auth = begin

                   Merb.logger.debug("Raw request: #{request.inspect}")
                   headers = request.env.inject({ }) { |memo, kv| memo[$2.downcase.to_sym] = kv[1] if kv[0] =~ /^(HTTP_)(.*)/; memo }
                   username = headers[:x_ops_userid].chomp
                   orgname = params[:organization_id]
                   Merb.logger.debug "I have #{headers.inspect}"
                   
                   user = begin
                            User.find(username)
                          rescue ArgumentError
                            if orgname
                              cr = database_from_orgname(orgname)
                              Client.on(cr).by_clientname(:key=>username).first
                            end
                          end
                   
                   actor = user_to_actor(user.id)
                   params[:requesting_actor_id] = actor.auth_object_id
                   user_key = OpenSSL::PKey::RSA.new(user.public_key)
                   Merb.logger.debug "authenticating:\n #{user.inspect}\n"
                   AuthenticateEvery::authenticator.authenticate_user_request(request, user_key)
                 rescue StandardError => se
                   Merb.logger.debug "authenticate every failed: #{se}, #{se.backtrace}"
                   nil
                 end
          raise Merb::ControllerExceptions::Unauthorized, "Failed authorization" unless auth          
          auth
        end
      end
    end
  end
end
