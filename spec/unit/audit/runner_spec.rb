require "spec_helper"

describe Chef::Audit::Runner do
  describe "#enabled?" do
    before do
      # stub logger
    end

    it "is true if the node attributes have audit profiles and the audit cookbook is not present"
    it "is false if the node attributes have audit profiles and the audit cookbook is present"
    it "is false if the node attributes do not have audit profiles and the audit cookbook is not present"
    it "is false if the node attributes do not have audit profiles and the audit cookbook is present"
  end
end
