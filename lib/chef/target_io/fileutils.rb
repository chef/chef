module TargetIO
  class FileUtils
    class << self
      def method_missing(m, **kwargs, *args, &block)
        Chef::Log.debug format('FileUtils::%s(%s)', m.to_s, args.join(', '))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::FileUtils : ::FileUtils
        backend.send(m, **kwargs, *args, &block)
      end
    end
  end
end
