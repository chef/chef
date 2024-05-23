module TargetIO
  class Dir
    class << self
      def method_missing(m, *args, **kwargs, &block)
        Chef::Log.debug format("Dir::%s(%s)", m.to_s, args.join(", "))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::Dir : ::Dir
        backend.send(m, *args, **kwargs, &block)
      end
    end
  end
end
