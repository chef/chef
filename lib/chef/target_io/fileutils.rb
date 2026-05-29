module TargetIO
  class FileUtils
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("FileUtils::%s(%s)", m.to_s, args.join(", "))

        backend = if TargetIO::FeatureFlags.target_io_backend_helper_enabled?
                    TargetIO::FeatureFlags.choose_backend(name: "TargetIO::FileUtils", target_backend: TrainCompat::FileUtils, local_backend: ::FileUtils)
                  else
                    ChefConfig::Config.target_mode? ? TrainCompat::FileUtils : ::FileUtils
                  end
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
