#
# Author:: John McCrae (<john.mccrae@progress.com>)
# Copyright:: Copyright (c) 2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "rubygems"
require "rake"

begin
  require "rspec/core/rake_task"

  namespace :target_mode do
    desc "Run target mode unit specs (spec/unit/target_io/)"
    RSpec::Core::RakeTask.new(:specs) do |t|
      puts "--- Running target_mode specs"
      t.verbose = false
      t.rspec_opts = %w{--profile --format doc}
      t.pattern = FileList["spec/unit/target_io/**/*_spec.rb"]
    end

    desc "Static analysis: scan target-mode-capable providers for TargetIO bypasses"
    task :static_analysis do
      # IO methods that must be routed through TargetIO in target-mode providers
      io_methods = %w{read write open readlines read_nonblock write_nonblock binread binwrite
                      foreach gets puts print each_line}.freeze
      file_io_pattern = /(?<!\w)(::File|(?<![A-Za-z:])File)\.(#{io_methods.join("|")})\b/

      # Discover providers that explicitly advertise target_mode support via their own
      # `provides :resource_name, target_mode: true` declaration.
      tm_provider_files = Dir["lib/chef/provider/**/*.rb"].select do |f|
        File.read(f).match?(/provides\s+:\w+.*target_mode:\s*true/)
      end

      violations = []
      tm_provider_files.each do |provider_file|
        File.read(provider_file).each_line.with_index(1) do |line, lineno|
          next if line.strip.start_with?("#")

          if (m = line.match(file_io_pattern))
            violations << { file: provider_file, line: lineno, match: m[0].strip }
          end
        end
      end

      if violations.any?
        puts "\n⚠️  Target Mode Static Analysis — Potential TargetIO bypasses found:"
        violations.each { |v| puts "  #{v[:file]}:#{v[:line]}  #{v[:match]}" }
        puts ""
        puts "These File IO calls will operate on the LOCAL system, not the remote target."
        puts "Replace with ::TargetIO::File.<method> for remote file operations."
        exit 1
      else
        puts "✅ Target Mode Static Analysis: No TargetIO IO bypasses found in #{tm_provider_files.size} target-mode provider(s)."
      end
    end

    desc "Run specs for changed files that declare target_mode support (comma-separated list of lib/ paths)"
    task :changed_files, [:files] do |_, args|
      changed = args[:files].to_s.split(/[,\s]+/).reject(&:empty?)

      if changed.empty?
        puts "target_mode:changed_files — no changed files supplied."
        next
      end

      spec_files = []
      changed.each do |changed_file|
        # Normalize: accept both bare basenames and full lib/ paths
        full_path = changed_file.start_with?("lib/") ? changed_file : "lib/chef/#{changed_file}"
        next unless File.exist?(full_path)

        # Only process files that declare target_mode support
        content = File.read(full_path)
        next unless content.match?(/target_mode\s*support:\s*:full|provides\s+:\w+.*target_mode:\s*true/)

        base = File.basename(full_path, ".rb")

        # Glob for specs (handles flat and nested layouts)
        Dir.glob("spec/unit/{resource,provider}/**/#{base}_spec.rb").each do |spec|
          spec_files << spec unless spec_files.include?(spec)
        end
      end

      if spec_files.empty?
        puts "target_mode:changed_files — no matching specs found for the supplied files."
        next
      end

      puts "--- Running specs for changed target-mode files:"
      spec_files.each { |f| puts "  #{f}" }
      sh "bundle exec rspec #{spec_files.join(" ")} --format doc"
    end

    desc "Run target-mode transport integration tests (requires TM_INTEGRATION_ENABLED=true and live targets)"
    RSpec::Core::RakeTask.new(:integration) do |t|
      puts "--- Running target_mode integration tests"
      t.verbose = false
      t.rspec_opts = %w{--profile --format doc}
      t.pattern = FileList["spec/integration/target_mode/**/*_spec.rb"]
    end
  end

rescue LoadError
  $stderr.puts "\n*** RSpec not available. bundle install first to run target_mode tasks. ***\n\n"
end
