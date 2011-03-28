require 'chef/knife'
require 'chef/node'

class Chef
  class Knife
    class TagDelete < Knife

      banner "knife tag delete NODE TAG ..."

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
          node.tags.delete tag
        end
      end
    end
  end
end
