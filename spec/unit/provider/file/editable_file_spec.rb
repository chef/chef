#
# Copyright:: Copyright 2018-2018, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Provider::File::EditableFile do

  let(:tempfile_contents) do
    %W{
      LINE1\n
      \tLINE2\n
      \tLINE3\t\n
      LINE4\t\n
      EMBEDDED\t\t\tWHIT\\SPACE\n
      LINE5\n
    }.join
  end

  let(:tempfile_array) { tempfile_contents.lines }

  let(:tempfile) do
    t = Tempfile.new
    t.write(tempfile_contents)
    t.close
    t
  end

  let(:editor) { Chef::Provider::File::EditableFile.from_file(tempfile.path) }

  after(:each) do
    tempfile.unlink
  end

  describe "#insert" do
    let(:insert_line) { "LINE" } # should be a substr match to at least one line in :tempfile_contents

    context "when doing basic functionality" do
      it "the default location is to append to the end" do
        editor.location :end
        editor.insert insert_line, location: :end
        editor.finish!
        expect( IO.read(tempfile) ).to eql( (tempfile_array + ["#{insert_line}\n"]).join )
      end

      it "and that is idempotent" do
        editor.location :end
        editor.insert insert_line, location: :end
        editor.insert insert_line, location: :end
        editor.finish!
        expect( IO.read(tempfile) ).to eql( (tempfile_array + ["#{insert_line}\n"]).join )
      end

      it "and is not idempotent if we tell it not to be" do
        editor.location :end
        editor.insert insert_line, location: :end
        editor.insert insert_line, location: :end, idempotency: false
        editor.finish!
        expect( IO.read(tempfile) ).to eql( (tempfile_array + ["#{insert_line}\n"] + ["#{insert_line}\n"]).join )
      end

      it "we can also prepend before the end" do
        editor.location :end do
          before true
        end
        editor.insert insert_line, location: :end
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(-2, "#{insert_line}\n").join )
      end

      it "and that is idempotent" do
        editor.location :end do
          before true
        end
        editor.insert insert_line, location: :end
        editor.insert insert_line, location: :end
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(-2, "#{insert_line}\n").join )
      end

      it "and is not idempotent if we tell it not to be" do
        editor.location :end do
          before true
        end
        editor.insert insert_line, location: :end
        editor.insert insert_line, location: :end, idempotency: false
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(-2, "#{insert_line}\n").insert(-2, "#{insert_line}\n").join )
      end

      it "we can prepend to the first line" do
        editor.location :start do
          before true
          first true
        end
        editor.insert insert_line, location: :start
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(0, "#{insert_line}\n").join )
      end

      it "and that is idempotent" do
        editor.location :start do
          before true
          first true
        end
        editor.insert insert_line, location: :start
        editor.insert insert_line, location: :start
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(0, "#{insert_line}\n").join )
      end

      it "and is not idempotent if we tell it not to be" do
        editor.location :start do
          before true
          first true
        end
        editor.insert insert_line, location: :start
        editor.insert insert_line, location: :start, idempotency: false
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(0, "#{insert_line}\n").insert(0, "#{insert_line}\n").join )
      end

      it "we can append after the first line" do
        editor.location :start do
          after true
          first true
        end
        editor.insert insert_line, location: :start
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(1, "#{insert_line}\n").join )
      end

      it "and that is idempotent" do
        editor.location :start do
          after true
          first true
        end
        editor.insert insert_line, location: :start
        editor.insert insert_line, location: :start
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(1, "#{insert_line}\n").join )
      end

      it "and is not idempotent if we tell it not to be" do
        editor.location :start do
          after true
          first true
        end
        editor.insert insert_line, location: :start
        editor.insert insert_line, location: :start, idempotency: false
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.insert(1, "#{insert_line}\n").insert(1, "#{insert_line}\n").join )
      end
    end

    context "when ignoring whitespace" do
      it "can ignore leading whitespace in the idempotency check" do
        editor.location :end
        editor.insert "LINE2", location: :end, ignore_leading: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "ignoring leading whitespace does not ignore trailing" do
        editor.location :end
        editor.insert "LINE3", location: :end, ignore_leading: true
        editor.finish!
        expect( IO.read(tempfile) ).not_to eql( tempfile_array.join )
      end

      it "can ignore trailing whitespace in the idempotency check" do
        editor.location :end
        editor.insert "LINE4", location: :end, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "ignoring trailing whitespace does not ignore leading" do
        editor.location :end
        editor.insert "LINE3", location: :end, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).not_to eql( tempfile_array.join )
      end

      it "ignoring both ignores leading" do
        editor.location :end
        editor.insert "LINE3", location: :end, ignore_leading: true, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "ignoring both ignores trailing" do
        editor.location :end
        editor.insert "LINE4", location: :end, ignore_leading: true, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "ignoring both ignores both" do
        editor.location :end
        editor.insert "LINE5", location: :end, ignore_leading: true, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "ignoring both no matches is stil no matches" do
        editor.location :end
        editor.insert "LINE", location: :end, ignore_leading: true, ignore_trailing: true
        editor.finish!
        expect( IO.read(tempfile) ).not_to eql( tempfile_array.join )
      end

      it "ignores embedded whitespace properly (checks regular expression escaping as well)" do
        editor.location :end
        editor.insert "EMBEDDED WHIT\\SPACE", location: :end, ignore_embedded: true
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end
    end
  end

  describe "#delete" do
    context "when doing basic functionality" do
      it "delete the first line" do
        editor.delete "LINE1"
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.delete_at(1) )
      end

      it "delete the first line is idempotent" do
        editor.delete "LINE1"
        editor.delete "LINE1"
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.delete(1) )
      end

      it "delete lots of things with a regexp" do
        editor.delete /LINE/
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.reject { |i| i =~ /LINE/ }.join )
      end

      it "matches exactly by default" do
        editor.delete "LINE"
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.join )
      end

      it "takes an array of regexps" do
        editor.delete [ /LINE1/, /LINE3/ ]
        editor.finish!
        expect( IO.read(tempfile) ).to eql( tempfile_array.delete_at(1).delete_at(2).join )
      end
    end
  end
end
