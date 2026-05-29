#
# Copyright:: Copyright (c) 2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#

require "spec_helper"
require "open3"

describe "scripts/update_chef_config_architecture.sh" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "scripts/update_chef_config_architecture.sh") }
  let(:diagram_path) { File.join(repo_root, "ai-track-docs/chef-config-architecture.mmd") }
  let(:summary_path) { File.join(repo_root, "ai-track-docs/chef-config-architecture-change-summary.md") }

  it "generates the diagram and summary files" do
    stdout, stderr, status = Open3.capture3("bash", script_path)
    expect(status.success?).to be(true), "stdout: #{stdout}\nstderr: #{stderr}"

    expect(File.exist?(diagram_path)).to be(true)
    expect(File.exist?(summary_path)).to be(true)

    diagram = File.read(diagram_path)
    summary = File.read(summary_path)

    expect(diagram).to include("flowchart TD")
    expect(diagram).to include("chef-config subsystem")
    expect(summary).to include("chef-config Architecture Change Summary")
    expect(summary).to include("Before/After Evidence")
  end
end
