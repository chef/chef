name "role_test"
description "A simple test role"
default_attributes(
  :reason => "unbalancing",
  :ossining => "this time around"
)
override_attributes(
  :snakes => "on a plane",
  :ossining => "whatever"
)
recipes "roles"
