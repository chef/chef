#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

SOURCE = File.join(File.dirname(__FILE__), "..", "MAINTAINERS.toml")
TARGET = File.join(File.dirname(__FILE__), "..", "MAINTAINERS.md")

# The list of repositories that teams should own
REPOSITORIES = ["chef/chef", "chef/chef-census", "chef/chef-repo",
                "chef/client-docs", "chef/ffi-yajl", "chef/libyajl2-gem",
                "chef/mixlib-authentication", "chef/mixlib-cli",
                "chef/mixlib-config", "chef/mixlib-install", "chef/mixlib-log",
                "chef/mixlib-shellout", "chef/ohai", "chef/omnibus-chef"]

begin
  require "tomlrb"
  require "octokit"
  require "pp"

  namespace :maintainers do
    task :default => :generate

    desc "Generate MarkDown version of MAINTAINERS file"
    task :generate do
      out = "<!-- This is a generated file. Please do not edit directly -->\n\n"
      out << "# " + source["Preamble"]["title"] + "\n\n"
      out << source["Preamble"]["text"] + "\n"

      # The project lead is a special case
      out << "# " + source["Org"]["Lead"]["title"] + "\n\n"
      out << format_person(source["Org"]["Lead"]["person"]) + "\n\n"

      out << format_components(source["Org"]["Components"])
      File.open(TARGET, "w") do |fn|
        fn.write out
      end
    end

    desc "Synchronize GitHub teams"
    # there's a special @chef/client-maintainers team that's everyone
    # and then there's a team per component
    task :synchronize do
      Octokit.auto_paginate = true
      get_github_teams
      prepare_teams(source["Org"]["Components"].dup)
      sync_teams!
    end
  end

  def github
    @github ||= Octokit::Client.new(:netrc => true)
  end

  def source
    @source ||= Tomlrb.load_file SOURCE
  end

  def teams
    @teams ||= { "client-maintainers" => { "title" => "Client Maintainers" } }
  end

  def add_members(team, name)
    teams["client-maintainers"]["members"] ||= []
    teams["client-maintainers"]["members"] << name
    teams[team] ||= {}
    teams[team]["members"] ||= []
    teams[team]["members"] << name
  end

  def set_team_title(team, title)
    teams[team] ||= {}
    teams[team]["title"] = title
  end

  def gh_teams
    @gh_teams ||= {}
  end

  # we have to resolve team names to ids. While we're at it, we can get the privacy
  # setting, so we know whether we need to update it
  def get_github_teams
    github.org_teams("chef").each do |team|
      gh_teams[team[:slug]] = { "id" => team[:id], "privacy" => team[:privacy] }
    end
  end

  def get_github_team(team)
    github.team_members(gh_teams[team]["id"]).map do |member|
      member[:login]
    end.sort.uniq.map(&:downcase)
  rescue
    []
  end

  def create_team(team)
    puts "creating new github team: #{team} with title: #{teams[team]["title"]} "
    t = github.create_team("chef", name: team, description: teams[team]["title"],
                                   privacy: "closed", repo_names: REPOSITORIES,
                                   accept: "application/vnd.github.ironman-preview+json")
    gh_teams[team] = { "id" => t[:id], "privacy" => t[:privacy] }
  end

  def compare_teams(current, desired)
    # additions are the subtraction of the current state from the desired state
    # deletions are the subtraction of the desired state from the current state
    [desired - current, current - desired]
  end

  def prepare_teams(cmp)
    %w{text paths}.each { |k| cmp.delete(k) }
    if cmp.key?("team")
      team = cmp.delete("team")
      add_members(team, cmp.delete("lieutenant")) if cmp.key?("lieutenant")
      add_members(team, cmp.delete("maintainers")) if cmp.key?("maintainers")
      set_team_title(team, cmp.delete("title"))
    else
      %w{maintainers lieutenant title}.each { |k| cmp.delete(k) }
    end
    cmp.each { |_k, v| prepare_teams(v) }
  end

  def update_team(team, additions, deletions)
    create_team(team) unless gh_teams.key?(team)
    update_team_privacy(team)
    add_team_members(team, additions)
    remove_team_members(team, deletions)
  rescue
    puts "failed for #{team}"
  end

  def update_team_privacy(team)
    return if gh_teams[team]["privacy"] == "closed"
    puts "Setting #{team} privacy to closed from #{gh_teams[team]["privacy"]}"
    github.update_team(gh_teams[team]["id"], privacy: "closed",
                                             accept: "application/vnd.github.ironman-preview+json")
  end

  def add_team_members(team, additions)
    additions.each do |member|
      puts "Adding #{member} to #{team}"
      github.add_team_membership(gh_teams[team]["id"], member, role: "member",
                                                               accept: "application/vnd.github.ironman-preview+json")
    end
  end

  def remove_team_members(team, deletions)
    deletions.each do |member|
      puts "Removing #{member} from #{team}"
      github.remove_team_membership(gh_teams[team]["id"], member,
                                    accept: "application/vnd.github.ironman-preview+json")
    end
  end

  def sync_teams!
    teams.each do |name, details|
      current = get_github_team(name)
      desired = details["members"].flatten.sort.uniq.map(&:downcase)
      additions, deletions = compare_teams(current, desired)
      update_team(name, additions, deletions)
    end
  end

  def get_person(person)
    source["people"][person]
  end

  def format_components(cmp)
    out = "## " + cmp.delete("title") + "\n\n"
    out << cmp.delete("text") + "\n" if cmp.has_key?("text")
    out << "To mention the team, use @chef/#{cmp.delete("team")}\n\n" if cmp.has_key?("team")
    if cmp.has_key?("lieutenant")
      out << "### Lieutenant\n\n"
      out << format_person(cmp.delete("lieutenant")) + "\n\n"
    end
    out << format_maintainers(cmp.delete("maintainers")) + "\n" if cmp.has_key?("maintainers")
    cmp.delete("paths")
    cmp.each { |k, v| out << format_components(v) }
    out
  end

  def format_maintainers(people)
    o = "### Maintainers\n\n"
    people.each do |p|
      o << format_person(p) + "\n"
    end
    o
  end

  def format_person(person)
    mnt = get_person(person)
    "* [#{mnt["Name"]}](https://github.com/#{mnt["GitHub"]})"
  end

rescue LoadError
  STDERR.puts "\n*** TomlRb not available.\n\n"
end
