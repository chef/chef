##
# Nodes should have a unique name
##
name "test.example.com-default"

##
# Nodes can set arbitrary arguments
##
sunshine "in"
something "else"

##
# Nodes should have recipes
##
recipes "operations-master", "operations-monitoring"
