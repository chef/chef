control_group "omnitruck" do
  require 'chef/http'
  require 'chef/json_compat'

  # We do this to be able to reference 'rest' both inside and outside example
  # blocks
  rest = Chef::HTTP.new("https://omnitruck.chef.io/chef/metadata", headers: {"Accept" => "application/json"})
  let(:rest) { rest }

  def request(url)
    Chef::JSONCompat.parse(rest.get(url))["sha256"]
  end

  shared_examples "32 matches 64" do |version|
    it "only returns 32-bit packages" do
      sha32 = request("?p=windows&pv=2012r2&v=#{version}&m=i386")
      sha64 = request("?p=windows&pv=2012r2&v=#{version}&m=x86_64")
      expect(sha32).to eq(sha64)
    end
  end

  context "from the current channel" do
    it "returns both 32-bit and 64-bit packages" do
      # We cannot verify from the returned URL if the package is 64 or 32 bit because
      # it is often lying, so we just make sure they are different.
      # The current channel is often cleaned so only the latest builds are in
      # it, so we just request the latest version instead of trying to check
      # old versions
      sha32 = request("?p=windows&pv=2012r2&m=i386&prerelease=true")
      sha64 = request("?p=windows&pv=2012r2&m=x86_64&prerelease=true")
      expect(sha32).to_not eq(sha64)
    end
  end

  context "from the stable channel" do
    %w{11 12.3 12.4.2 12.6.0 12.8.1}.each do |version|
      describe "with version #{version}" do
        include_examples "32 matches 64", version
      end
    end

    begin
      rest.get("?p=windows&pv=2012r2&v=12.9")
      describe "with version 12.9" do
        it "returns both 32-bit and 64-bit packages" do
          sha32 = request("?p=windows&pv=2012r2&v=12.9&m=i386")
          sha64 = request("?p=windows&pv=2012r2&v=12.9&m=x86_64")
          expect(sha32).to_not eq(sha64)
        end
      end
    rescue Net::HTTPServerException => e
      # Once 12.9 is released this will stop 404ing and the example
      # will be executed
      unless e.response.code == "404"
        raise
      end
    end

  end

end
