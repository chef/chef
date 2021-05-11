require "spec_helper"
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::HabitatPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::HabitatPackage,
    provider: Chef::Provider::Package::Habitat,
    name: :habitat_package,
    action: :install,
  )

end

describe Chef::Resource::DnfPackage, "defaults" do
let(:resource) { Chef::Resource::HabitatPackage.new("core/redis") }

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "has a resource name of habitat_package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)

    it "supports :install, :remove, :upgrade actions" do
      expect { resource.action :install }.not_to raise_error
      expect { resource.action :remove }.not_to raise_error
      expect { resource.action :upgrade }.not_to raise_error
    end

    it "installs core/redis" do
      expect(resource.package_name).to eql("core/redis")
    end

    it "installs lamont-granquist/ruby with a specific version" do
      resource.package_name("lamont-granquist/ruby")
      resource.version("2.3.1")
      expect(resource.package_name).to eql("lamont-granquist/ruby")
      expect(resource.version).to eql("2.3.1")
    end

    it "installs core/bundler with a specific release" do
      resource.packane_name("core/bundler")
      resource.version("1.13.3/20161011123917")
      expect(resoure.package_name).to eql("core/bundler")
      expect(resource.version).to eql("1.13.3/20161011123917")
    end

    it "installs core/hab-sup with a specific depot url" do
      resource.packane_name("core/hab-sup")
      resource.bldr_url("https://bldr.habitat.sh")
      expect(resource.package_name).to eql("core/hab-sup")
      expect(resource.bldr_url).to eql("https://bldr.habitat.sh")
    end

    it "installs core/foo with option binlink" do
      resource.package_name("core/foo")
      resource.binlink(true)
      expect(resource.package_name).to eql("core/foo")
      expect(resource.binlink).to eql(true)
    end

    it "installs core/foo by forcing binlink" do
      expect(resource.package_name).to eql("core/foo")
        .with(binlink: :force)
    end

    it "removes core/nginx with remove action" do
      resource.action("remove")
      expect(resource.action).to remove_habitat_package("core/nginx")
    end
  end
end
