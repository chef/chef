module TargetIO
  class IO
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("IO::%s(%s)", m.to_s, args.join(", "))

        backend = if TargetIO::FeatureFlags.target_io_backend_helper_enabled?
                    TargetIO::FeatureFlags.choose_backend(name: "TargetIO::IO", target_backend: TrainCompat::IO, local_backend: ::IO)
                  else
                    ChefConfig::Config.target_mode? ? TrainCompat::IO : ::IO
                  end
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
