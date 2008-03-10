#
# Example config
#

nodes_from([ 
  Chef::Node::YAML => {
    :search_path => [ "/etc/chef/nodes" ]
  }, 
  Chef::Node::PuppetExternalNode => {
    :command => ""
  },
  :rest => {
    :search_url => "http://localhost:3000/nodes/#{node_name}"
  }, 
  :iclassify => {
    :search_url => "http://localhost:3000/nodes/#{node_name}"
  }
])


