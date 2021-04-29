##
# Nodes should have a unique name
##
name "test.example.com-short"

##
# Nodes can set arbitrary arguments
##
default[:sunshine] = "in"
default[:something] = "else"

##
# Nodes should have recipes
##
run_list "operations-master", "operations-monitoring"
