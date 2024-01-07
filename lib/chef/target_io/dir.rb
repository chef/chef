module TargetIO
  class Dir
    class << self
      def method_missing(m, **kwargs, *args, &block)
        Chef::Log.debug format('Dir::%s(%s)', m.to_s, args.join(', '))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::Dir : ::Dir
        backend.send(m, **kwargs, *args, &block)
      end
    end
  end
end
