module TargetIO
  class Dir
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("Dir::%s(%s)", m.to_s, args.join(", "))

        backend = if TargetIO::FeatureFlags.target_io_backend_helper_enabled?
                    TargetIO::FeatureFlags.choose_backend(name: "TargetIO::Dir", target_backend: TrainCompat::Dir, local_backend: ::Dir)
                  else
                    ChefConfig::Config.target_mode? ? TrainCompat::Dir : ::Dir
                  end
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
