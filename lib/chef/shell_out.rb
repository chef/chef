require 'mixlib/shellout'

class Chef
  class ShellOut < Mixlib::ShellOut

    def initialize(*args)
      Chef::Log.warn("Chef::ShellOut is deprecated, please use Mixlib::ShellOut")
      called_from = caller[0..3].inject("Called from:\n") {|msg, trace_line| msg << "  #{trace_line}\n" }
      Chef::Log.warn(called_from)
      super
    end
  end
end
