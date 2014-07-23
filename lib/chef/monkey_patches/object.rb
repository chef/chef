class Object
  unless new.respond_to?(:tap)
    def tap
      yield self
      self
    end
  end
end
