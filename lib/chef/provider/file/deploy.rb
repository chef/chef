

class Chef
  class Provider
    class File
      class Deploy
        def self.strategy(deploy_with)
          case deploy_with
          when :move
            Chef::Platform.windows? ?  MvWindows.new() : MvUnix.new()
          when :copy
            Cp.new()
          else
            raise "invalid deployment strategy use :move or :copy"
          end
        end
      end
    end
  end
end

