
require "net/http"
require "uri"

require "#{ENV['BUSSER_ROOT']}/../kitchen/data/serverspec_helper"

describe "webapp::default" do
  describe "installed packages" do
    shared_examples_for "a package" do
      it "is installed" do
        expect(package(package_name)).to be_installed
      end
    end

    describe "#{property[:apache][:package]} package" do
      include_examples "a package" do
        let(:package_name) { property[:apache][:package] }
      end
    end

    describe "mysql-server-#{property[:mysql][:server][:version]} package" do
      include_examples "a package" do
        let(:package_name) { "mysql-server-#{property[:mysql][:server][:version]}" }
      end
    end

    describe "mysql-client package" do
      include_examples "a package" do
        let(:package_name) { "mysql-client" }
      end
    end

    describe "php package" do
      include_examples "a package" do
        let(:package_name) { "php5" }
      end
    end
  end

  describe "enabled/running services" do
    shared_examples_for "a service" do
      it "is enabled" do
        expect(service(service_name)).to be_enabled
      end

      it "is running" do
        expect(service(service_name)).to be_enabled
      end
    end

    describe "#{property[:apache][:service_name]} service" do
      include_examples "a service" do
        let(:service_name) { property[:apache][:service_name] }
      end
    end

    describe "mysql service" do
      include_examples "a service" do
        let(:service_name) { "mysql" }
      end
    end

  end

  describe "mysql database" do
    let(:db_query) { "mysql -u root -pilikerandompasswordstoo -e \"#{statement}\"" }
    let(:statement) { "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='webapp'" }
    it "creates a database called 'webapp'" do
      expect(command(db_query)).to return_stdout(/webapp/)
    end

    describe "mysql database user 'webapp'" do
      let(:statement) { "SELECT Host, Db FROM mysql.db WHERE User='webapp'\\G" }
      it "adds user 'webapp' to database 'webapp@localhost'" do
        expect(command(db_query)).to return_stdout(/Host: localhost\n  Db: webapp/)
      end

      describe "grants" do
        shared_examples_for "a privilege" do |priv|
          let(:statement) {
            "SELECT #{priv_query}" \
            " FROM mysql.db" \
            " WHERE Host='localhost' AND Db='webapp' AND User='webapp'\\G"
          }
          let(:priv_query) { "#{priv.capitalize}_priv" }

          it "has privilege #{priv} on 'webapp@localhost'" do
            expect(command(db_query)).to return_stdout(/#{priv_query}: Y/)
          end
        end

        %w(select update insert delete create).each do |priv|
          include_examples "a privilege", priv do
          end
        end
      end
    end
  end

  describe "generated webpages" do
    let(:get_response) { Net::HTTP.get_response(uri) }
    shared_examples_for "a webpage" do
      it "exists" do
        expect(get_response).to be_kind_of(Net::HTTPSuccess)
      end

      it "displays content" do
        expect(get_response.body).to include(content)
      end
    end

    describe "http://localhost/index.html" do
      include_examples "a webpage" do
        let(:uri) { URI.parse("http://localhost/index.html") }
        let(:content) { "Hello, World!" }
      end
    end

    describe "http://localhost/index.php" do
      include_examples "a webpage" do
        let(:uri) { URI.parse("http://localhost/index.php") }
        let(:content) { "Hello, World!" }
      end
    end
  end
end
