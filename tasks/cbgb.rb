#
# Author:: Thom May (tmay@chef.io)
# Author:: Nathen Harvey (nharvey@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc
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

require "rake"

CBGB_SOURCE = File.join(File.dirname(__FILE__), "..", "CBGB.toml")
CBGB_TARGET = File.join(File.dirname(__FILE__), "..", "CBGB.md")

begin
  require "tomlrb"

  task :default => :generate

  namespace :cbgb do
    desc "Generate MarkDown version of CBGB file"
    task :generate do
      cbgb = Tomlrb.load_file CBGB_SOURCE
      out = "<!-- This is a generated file. Please do not edit directly -->\n"
      out << "<!-- Modify CBGB.toml file and run `rake cbgb:generate` to regenerate -->\n\n"
      out << "# " + cbgb["Preamble"]["title"] + "\n\n"
      out << cbgb["Preamble"]["text"] + "\n"
      out << "# Board of Governors\n\n"
      out << "## " + cbgb["Org"]["Lead"]["title"] + "\n\n"
      out << person(cbgb["people"], cbgb["Org"]["Lead"]["person"]) + "\n\n"
      out << "### " + cbgb["Org"]["Contributors"]["title"] + "\n\n"
      out << cbgb(cbgb["people"], cbgb["Org"]["Contributors"]["governers"]) + "\n\n"
      out << "### " + cbgb["Org"]["Corporate-Contributors"]["title"] + "\n\n"
      out << cbgb(cbgb["corporations"], cbgb["Org"]["Corporate-Contributors"]["governers"]) + "\n\n"
      out << "### " + cbgb["Org"]["Lieutenants"]["title"] + "\n\n"
      out << cbgb(cbgb["people"], cbgb["Org"]["Lieutenants"]["governers"]) + "\n\n"
      File.open(CBGB_TARGET, "w") do |fn|
        fn.write out
      end
    end
  end

  def components(list, cmp)
    out = ""
    cmp.each do |k, v|
      out << "\n#### #{v['title'].gsub('#', '\\#')}\n"
      out << cbgb(list, v["cbgb"])
    end
    out
  end

  def cbgb(list, people)
    o = ""
    people.each do |p|
      o << person(list, p) + "\n"
    end
    o
  end

  def person(list, person)
    if list[person].has_key?("GitHub")
      out = "* [#{list[person]["Name"]}](https://github.com/#{list[person]["GitHub"]})"
    else
      out =  "* #{list[person]["Name"]}"
    end
    if list[person].has_key?("Person")
      out << " - #{list[person]["Person"]}"
    end
    out
  end

rescue LoadError
  STDERR.puts "\n*** TomlRb not available.\n\n"
end
