module TargetIO
  module Shadow
    # sp_namp - pointer to null-terminated user name.
    # sp_pwdp - pointer to null-terminated password.
    # sp_lstchg - days  since  Jan  1,  1970 password was last
    #             changed.
    # sp_min - days before which password may not be changed.
    # sp_max - days after which password must be changed.
    # sp_warn - days before password is to expire that  user  is
    #           warned of pending password expiration.
    # sp_inact  -  days  after  password expires that account is
    #              considered inactive and disabled.
    # sp_expire - days since Jan 1, 1970 when  account  will  be
    #             disabled
    # sp_loginclass - pointer to null-terminated user login class.
    Entry = Struct.new(
      :sp_namp,
      :sp_pwdp,
      :sp_lstchg,
      :sp_min,
      :sp_max,
      :sp_warn,
      :sp_inact,
      :sp_expire,
      :sp_loginclass
    )

    class Passwd
      class << self

        def method_missing(m, *args, **kwargs, &block)
          Chef::Log.debug format("Shadow::Passwd::%s(%s)", m.to_s, args.join(", "))

          if ChefConfig::Config.target_mode? && !Chef.run_context.transport_connection.os.unix?
            raise "Shadow support only on Unix, this is " + Chef.run_context.transport_connection.platform.title
          end

          backend = ChefConfig::Config.target_mode? ? TrainCompat::Shadow::Passwd : ::Shadow::Passwd
          backend.send(m, *args, **kwargs, &block)
        end
      end
    end
  end
end
