##
# Nodes should have a unique name
##
name "test.example.com"

##
# Nodes can set arbitrary arguments
##
normal[:sunshine] = "in"
normal[:something] = "else"

##
# Nodes should have recipes
##
run_list "operations-master", "operations-monitoring"

chef_environment "dev"
