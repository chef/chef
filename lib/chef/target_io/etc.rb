module TargetIO
  class Etc
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("Etc::%s(%s)", m.to_s, args.join(", "))

        if ChefConfig::Config.target_mode? && !Chef.run_context.transport_connection.os.unix?
          raise "Etc support only on Unix, this is " + Chef.run_context.transport_connection.platform.title
        end

        backend = ChefConfig::Config.target_mode? ? TrainCompat::Etc : ::Etc
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
