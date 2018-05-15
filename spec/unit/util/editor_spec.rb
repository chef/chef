require "spec_helper"
require "chef/util/editor"

describe Chef::Util::Editor do
  describe "#initialize" do
    it "takes an Enumerable of lines" do
      editor = described_class.new(File.open(__FILE__))
      expect(editor.lines).to be == IO.readlines(__FILE__)
    end

    it "makes a copy of an Array" do
      array = Array.new
      editor = described_class.new(array)
      expect(editor.lines).to_not be(array)
    end
  end

  subject(:editor) { described_class.new(input_lines) }
  let(:input_lines) { %w{one two two three} }

  describe "#append_line_after" do
    context "when there is no match" do
      subject(:execute) { editor.append_line_after("missing", "new") }

      it("returns the number of added lines") { is_expected.to eq(0) }
      it "does not add any lines" do
        expect { execute }.to_not change { editor.lines }
      end
    end

    context "when there is a match" do
      subject(:execute) { editor.append_line_after("two", "new") }

      it("returns the number of added lines") { is_expected.to eq(2) }
      it "adds a line after each match" do
        execute
        expect(editor.lines).to be == %w{one two new two new three}
      end
    end

    it "matches a Regexp" do
      expect(editor.append_line_after(/^ee/, "new")).to be == 0
      expect(editor.append_line_after(/ee$/, "new")).to be == 1
    end
  end

  describe "#append_line_if_missing" do
    context "when there is no match" do
      subject(:execute) { editor.append_line_if_missing("missing", "new") }

      it("returns the number of added lines") { is_expected.to eq(1) }
      it "adds a line to the end" do
        execute
        expect(editor.lines).to be == %w{one two two three new}
      end
    end

    context "when there is a match" do
      subject(:execute) { editor.append_line_if_missing("one", "new") }

      it("returns the number of added lines") { is_expected.to eq(0) }
      it "does not add any lines" do
        expect { execute }.to_not change { editor.lines }
      end
    end

    it "matches a Regexp" do
      expect(editor.append_line_if_missing(/ee$/, "new")).to be == 0
      expect(editor.append_line_if_missing(/^ee/, "new")).to be == 1
    end
  end

  describe "#remove_lines" do
    context "when there is no match" do
      subject(:execute) { editor.remove_lines("missing") }

      it("returns the number of removed lines") { is_expected.to eq(0) }
      it "does not remove any lines" do
        expect { execute }.to_not change { editor.lines }
      end
    end

    context "when there is a match" do
      subject(:execute) { editor.remove_lines("two") }

      it("returns the number of removed lines") { is_expected.to eq(2) }
      it "removes the matching lines" do
        execute
        expect(editor.lines).to be == %w{one three}
      end
    end

    it "matches a Regexp" do
      expect(editor.remove_lines(/^ee/)).to be == 0
      expect(editor.remove_lines(/ee$/)).to be == 1
    end
  end

  describe "#replace" do
    context "when there is no match" do
      subject(:execute) { editor.replace("missing", "new") }

      it("returns the number of changed lines") { is_expected.to eq(0) }
      it "does not change any lines" do
        expect { execute }.to_not change { editor.lines }
      end
    end

    context "when there is a match" do
      subject(:execute) { editor.replace("two", "new") }

      it("returns the number of changed lines") { is_expected.to eq(2) }
      it "replaces the matching portions" do
        execute
        expect(editor.lines).to be == %w{one new new three}
      end
    end

    it "matches a Regexp" do
      expect(editor.replace(/^ee/, "new")).to be == 0
      expect(editor.replace(/ee$/, "new")).to be == 1
      expect(editor.lines).to be == %w{one two two thrnew}
    end
  end

  describe "#replace_lines" do
    context "when there is no match" do
      subject(:execute) { editor.replace_lines("missing", "new") }

      it("returns the number of changed lines") { is_expected.to eq(0) }
      it "does not change any lines" do
        expect { execute }.to_not change { editor.lines }
      end
    end

    context "when there is a match" do
      subject(:execute) { editor.replace_lines("two", "new") }

      it("returns the number of replaced lines") { is_expected.to eq(2) }
      it "replaces the matching line" do
        execute
        expect(editor.lines).to be == %w{one new new three}
      end
    end

    it "matches a Regexp" do
      expect(editor.replace_lines(/^ee/, "new")).to be == 0
      expect(editor.replace_lines(/ee$/, "new")).to be == 1
      expect(editor.lines).to be == %w{one two two new}
    end
  end
end
