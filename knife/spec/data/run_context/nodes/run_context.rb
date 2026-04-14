##
# Nodes should have a unique name
##
name "compile"
run_list "test", "test::one", "test::two"
