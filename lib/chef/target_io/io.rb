module TargetIO
  class IO
    class << self
      def method_missing(m, **kwargs, *args, &block)
        Chef::Log.debug format('IO::%s(%s)', m.to_s, args.join(', '))

        backend = ChefConfig::Config.target_mode? ? TrainCompat::IO : ::IO
        backend.send(m, **kwargs, *args, &block)
      end
    end
  end
end
