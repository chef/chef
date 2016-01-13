class Chef
  class Node
    module AttributeConstants

      COMPONENTS = [
        :@default,
        :@env_default,
        :@role_default,
        :@force_default,
        :@normal,
        :@override,
        :@role_override,
        :@env_override,
        :@force_override,
        :@automatic
      ].freeze

      DEFAULT_COMPONENTS = [
        :@default,
        :@env_default,
        :@role_default,
        :@force_default
      ].freeze

      OVERRIDE_COMPONENTS = [
        :@override,
        :@role_override,
        :@env_override,
        :@force_override
      ].freeze

      COMPONENTS_AS_SYMBOLS = COMPONENTS.map do |component|
        component.to_s[1..-1].to_sym
      end.freeze

      DEFAULT_COMPONENTS_AS_SYMBOLS = DEFAULT_COMPONENTS.map do |component|
        component.to_s[1..-1].to_sym
      end.freeze

      OVERRIDE_COMPONENTS_AS_SYMBOLS = OVERRIDE_COMPONENTS.map do |component|
        component.to_s[1..-1].to_sym
      end.freeze

    end
  end
end
