# For storing any examples shared between multiple tests

# Any object which defines a .to_json should import this test
shared_examples "to_json equalivent to Chef::JSONCompat.to_json" do

  it "should allow consumers to call #to_json or Chef::JSONCompat.to_json" do
    expect(subject.to_json).to eq(Chef::JSONCompat.to_json(subject))
  end

end
