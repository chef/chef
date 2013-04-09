

class Chef
  class Provider
    class File
      class Deploy
        def self.strategy(deployment_strategy)
          deployment_strategy ||= Chef::Config[:file_deployment_strategy]
          deployment_strategy ||= Chef::Platform.windows? ? :mv_windows : :mv_unix
          case deployment_strategy
          when :mv_windows
            Chef::Provider::File::Deploy::MvWindows.new()
          when :mv_unix
            Chef::Provider::File::Deploy::MvUnix.new()
          when :cp_unix
            Chef::Provider::File::Deploy::CpUnix.new()
          else
            raise "invalid deployment strategy use :mv_unix, :mv_windows or :cp_unix"
          end
        end
      end
    end
  end
end

