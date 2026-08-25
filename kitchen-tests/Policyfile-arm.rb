# Policyfile-arm.rb - dedicated Policyfile for the end_to_end_arm suite.
#
# Policyfile.rb (the default, autodetected one) hardcodes
# run_list "end_to_end::default" and only declares the "end_to_end" cookbook.
# kitchen-chef-enterprise's chef_infra provisioner always uses whichever
# Policyfile it finds to resolve the run_list, ignoring a suite's own
# run_list: setting entirely -- so testing end_to_end_arm requires its own
# separate Policyfile, selected per-suite via policyfile_path.

name "end_to_end_arm"

default_source :supermarket

run_list "end_to_end_arm::default"

cookbook "end_to_end_arm", path: "cookbooks/end_to_end_arm"
