
require 'chef/win32/api/registry'
require 'chef/win32/unicode'
require 'win32/registry'

module Win32
  class Registry
    module API
      
      extend Chef::ReservedNames::Win32::API::Registry

      module_function

      if RUBY_VERSION =~ /^2\.1/
        # ::Win32::Registry#delete_value is broken in Ruby 2.1 (up to Ruby 2.1.6).
        # This should be resolved in a later release (see note #9 in link below).
        # https://bugs.ruby-lang.org/issues/10820
        def DeleteValue(hkey, name)
          check RegDeleteValueW(hkey, name.to_wstring)
        end
      end

      # ::Win32::Registry#delete_key uses RegDeleteKeyW. We need to use
      # RegDeleteKeyExW to properly support WOW64 systems.
      def DeleteKey(hkey, name)
        check RegDeleteKeyExW(hkey, name.to_wstring, 0, 0)
      end
      
    end
  end
end