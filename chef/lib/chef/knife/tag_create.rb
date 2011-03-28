require 'chef/knife'
require 'chef/node'

class Chef
  class Knife
    class TagCreate < Knife

      banner "knife tag create NODE TAG ..."

      def run
        name = @name_args[0]
        tags = @name_args[1..-1].join(",").split(/\s*,\s*/)

        unless name or tags.empty?
          show_usage
          # TODO: blah blah
          ui.fatal("You must specify a name name")
          exit 1
        end

        node = Chef::Node.load name
        tags.each do |tag|
          node.tags << tag
        end
      end
    end
  end
end
