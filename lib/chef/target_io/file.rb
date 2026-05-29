module TargetIO
  class File
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("File::%s(%s)", m.to_s, args.join(", "))

        backend = if TargetIO::FeatureFlags.target_io_backend_helper_enabled?
                    TargetIO::FeatureFlags.choose_backend(name: "TargetIO::File", target_backend: TrainCompat::File, local_backend: ::File)
                  else
                    ChefConfig::Config.target_mode? ? TrainCompat::File : ::File
                  end
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
