class Chef
  class Dist
    # Some disclaimers about the ditribution you're using.
    # Distributions not produced by Chef are expect to change these messages
    # to indicate their distro is not the official Chef distro in compliance
    # with Chef's policy on Trademarks

    # The standard disclaimer
    DISCLAIMER = "You're running the community's experimental distribution `cinc` and not the official Chef Infra product. Visit https://Chef.io to learn more about Chef Infra by Chef".freeze

    # A shorter reminder
    REMINDER = "You're using `cinc`, the community distribution of chef"

    # The name of this distro
    DIST = "Cinc Infra".freeze

    # I'm probably not doing this right o.O
    module DistHelpers
      # Intended to suppress the message where appropriate
      def enterprise_distro?
        DIST == 'Chef Infra'
      end
    end
  end
end
