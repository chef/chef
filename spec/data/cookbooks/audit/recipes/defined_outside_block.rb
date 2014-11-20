controls "some more controls" do
  control "foo5"
end

# Even after seeing a `controls` block `control` should not work outside the block - even when running in rspec
control("foo4")
