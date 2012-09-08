module KnifeSpecs
  class TestExplicitCategory < Chef::Knife
    # i.e., the community site commands should be in the community site
    # category instead of cookbook (which is what would be assumed)
    category "community site"
  end
end
