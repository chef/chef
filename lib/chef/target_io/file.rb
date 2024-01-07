module TargetIO
  class File
    class << self
      def method_missing(m, **kwargs, *args, &block)
        Chef::Log.debug format('File::%s(%s)', m.to_s, args.join(', '))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::File : ::File
        backend.send(m, **kwargs, *args, &block)
      end
    end
  end
end
