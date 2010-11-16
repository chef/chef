module KnifeSpecs
  class TestYourself < Chef::Knife

    option :scro, :short => '-s SCRO', :long => '--scro SCRO', :description => 'a configurable setting'

    attr_reader :ran

    def run
      @ran = true
      self # return self so tests can poke at me
    end
  end
end
