require "spec_helper"

describe Chef::Application::Base, "setup_application" do
  let(:validation_path) { "" }

  context "when validation key is supplied" do
    before do
      @app = Chef::Application::Base.new
      tempfile = Tempfile.new(validation_path)
      tempfile.write "string"
      tempfile.close
      @path = tempfile.path
      Chef::Config.validation_key = @path
    end

    context "when key is in current directory" do
      it "should find with full path of validation_key" do
        validation_path = "validation.pem"
        expect(Chef::Config.validation_key).to eql(@path)
      end
    end

    context "when path is given" do
      validation_path = "/tmp/validation.pem"
      it "should find validation_key" do
        expect(Chef::Config.validation_key).to eql(@path)
      end
    end
  end

  context "when validation key is not supplied" do
    it "should return default path for validation_key" do
      if windows?
        expect(Chef::Config.validation_key).to eql("C:\\chef\\validation.pem")
      else
        expect(Chef::Config.validation_key).to eql("/etc/chef/validation.pem")
      end
    end
  end
end
