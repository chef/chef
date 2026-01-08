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

require "spec_helper"

class WorkerThreadError < StandardError
end

describe Chef::Util::ThreadedJobQueue do
  let(:queue) { Chef::Util::ThreadedJobQueue.new }

  around(:example) do |example|
    old_value = Thread.report_on_exception
    Thread.report_on_exception = false

    example.run

    Thread.report_on_exception = old_value
  end

  it "should pass mutex to jobs with an arity of 1" do
    job = double
    expect(job).to receive(:arity).at_least(:once).and_return(1)
    expect(job).to receive(:call).exactly(5).times.with(an_instance_of(Mutex))

    5.times { queue << job }
    queue.process
  end

  it "should pass nothing to jobs with an arity of 0" do
    job = double
    expect(job).to receive(:arity).at_least(:once).and_return(0)
    expect(job).to receive(:call).exactly(5).times.with(no_args)

    5.times { queue << job }
    queue.process
  end

  it "should use specified number of threads" do
    expect(Thread).to receive(:new).exactly(7).times.and_call_original
    queue.process(7)
  end

  it "should propagate exceptions to the main thread" do
    queue << lambda { raise WorkerThreadError }
    expect { queue.process }.to raise_error(WorkerThreadError)
  end
end
