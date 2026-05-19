#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "benchmark"
require "fileutils"
require "rake"
require "tmpdir"

TASK_FILE = File.expand_path("../tasks/spellcheck.rb", __dir__).freeze

WARMUP = Integer(ENV.fetch("BENCH_WARMUP", 20))
ITERATIONS = Integer(ENV.fetch("BENCH_ITERATIONS", 200))

def mean(values)
  values.sum / values.length.to_f
end

def variance(values)
  avg = mean(values)
  values.sum { |v| (v - avg)**2 } / values.length.to_f
end

def stddev(values)
  Math.sqrt(variance(values))
end

def percentile(values, p)
  return values.first if values.length == 1

  sorted = values.sort
  rank = p * (sorted.length - 1)
  lower = sorted[rank.floor]
  upper = sorted[rank.ceil]
  lower + (upper - lower) * (rank - rank.floor)
end

Dir.mktmpdir("spellcheck-bench") do |dir|
  Dir.chdir(dir) do
    File.write("cspell.json", '{"version":"0.2"}')

    Rake.application = Rake::Application.new
    load TASK_FILE

    task = Rake::Task["spellcheck:config_check"]

    WARMUP.times do
      task.reenable
      task.invoke
    end

    samples = Array.new(ITERATIONS) do
      task.reenable
      Benchmark.realtime { task.invoke }
    end

    avg = mean(samples)
    sd = stddev(samples)
    min = samples.min
    max = samples.max
    p50 = percentile(samples, 0.50)
    p95 = percentile(samples, 0.95)

    puts "benchmark=spellcheck:config_check"
    puts "ruby=#{RUBY_VERSION}"
    puts "warmup=#{WARMUP}"
    puts "iterations=#{ITERATIONS}"
    puts format("mean_ms=%.3f", avg * 1000.0)
    puts format("stddev_ms=%.3f", sd * 1000.0)
    puts format("cv_pct=%.2f", (sd / avg) * 100.0)
    puts format("min_ms=%.3f", min * 1000.0)
    puts format("p50_ms=%.3f", p50 * 1000.0)
    puts format("p95_ms=%.3f", p95 * 1000.0)
    puts format("max_ms=%.3f", max * 1000.0)
  end
end
