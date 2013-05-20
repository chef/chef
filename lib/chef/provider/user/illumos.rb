
class Chef
  class Provider
    class User
      class Illumos < Chef::Provider::User::Solaris

        def lock_user
          shell_out!("passwd -l #{@new_resource.username}")
        end

        def unlock_user
          shell_out!("passwd -u #{@new_resource.username}")
        end

        private

        def check_lock_status
          shell_out("passwd -s #{@new_resource.username}")
        end
      end
    end
  end
end
