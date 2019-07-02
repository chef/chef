expected_version="$(echo $TEST_PKG_IDENT | cut -d/ -f 3)"
@test "chef-infra-client runs" {
  run hab pkg exec $TEST_PKG_IDENT chef-client --version
  [ $status -eq 0 ]
}