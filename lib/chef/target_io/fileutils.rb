module TargetIO
  class FileUtils
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("FileUtils::%s(%s)", m.to_s, args.join(", "))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::FileUtils : ::FileUtils
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
