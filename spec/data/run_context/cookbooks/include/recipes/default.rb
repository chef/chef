module ::RanResources
  def self.resources
    @resources ||= []
  end
end
class RunContextCustomResource < Chef::Resource
  action :create do
    ruby_block '4' do
      block { RanResources.resources << 4 }
    end
    recipe_eval do
      ruby_block '1' do
        block { RanResources.resources << 1 }
      end
      include_recipe 'include::includee'
      ruby_block '3' do
        block { RanResources.resources << 3 }
      end
    end
    ruby_block '5' do
      block { RanResources.resources << 5 }
    end
  end
end
