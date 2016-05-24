require "chef/sugar"

# hack until this gets baked into chef-sugar so we can use chef-sugar in attributes files
Chef::Node.send(:include, Chef::Sugar::DSL)
