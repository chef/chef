# For storing any examples shared between multiple tests

# Any object which defines a .to_json should import this test
shared_examples "to_json equivalent to Chef::JSONCompat.to_json" do

  let(:jsonable) {
    raise "You must define the subject when including this test"
  }

  it "should allow consumers to call #to_json or Chef::JSONCompat.to_json" do
    expect(jsonable.to_json).to eq(Chef::JSONCompat.to_json(jsonable))
  end

end
