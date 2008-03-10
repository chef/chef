##
# Nodes should have a unique name
##
name "ops1prod"

##
# Nodes can set arbitrary arguments
##
sunshine "in"
something "else"

##
# Nodes should have recipes
##
recipes "operations-master", "operations-monitoring"
