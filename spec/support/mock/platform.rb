# makes Chef think it's running on a certain platform..useful for unit testing
# platform-specific functionality.
#
# If a block is given yields to the block with +RUBY_PLATFORM+ set to
# 'i386-mingw32' (windows) or 'x86_64-darwin11.2.0' (unix).  Useful for
# testing code that mixes in platform specific modules like +Chef::Mixin::Securable+
# or +Chef::FileAccessControl+
RSpec.configure do |c|
  c.include(Module.new do
    def platform_mock(platform = :unix)
      case platform
      when :windows
        Chef::Config.set_defaults_for_windows
        allow(ChefUtils).to receive(:windows?).and_return(true)
        stub_const("ENV", ENV.to_hash.merge("SYSTEMDRIVE" => "C:"))
        stub_const("RUBY_PLATFORM", "i386-mingw32")
        stub_const("File::PATH_SEPARATOR", ";")
        stub_const("File::ALT_SEPARATOR", "\\")
      when :unix
        Chef::Config.set_defaults_for_nix
        allow(ChefUtils).to receive(:windows?).and_return(false)
        stub_const("ENV", ENV.to_hash.merge("SYSTEMDRIVE" => nil))
        stub_const("RUBY_PLATFORM", "x86_64-darwin11.2.0")
        stub_const("File::PATH_SEPARATOR", ":")
        stub_const("File::ALT_SEPARATOR", nil)
      else
        raise "#{__method__}: unrecognized platform '#{platform}', expected one of ':unix' or ':windows'"
      end

      yield
    end
  end)
end
