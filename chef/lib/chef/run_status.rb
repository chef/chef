#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

class Chef::RunStatus

  attr_reader :run_context

  attr_writer :run_context

  attr_reader :start_time

  attr_reader :end_time

  attr_reader :exception

  attr_writer :exception

  def initialize(node)
    @node = node
  end

  def node
    @node
  end

  def start_clock
    @start_time = Time.now
  end

  def stop_clock
    @end_time = Time.now
  end

  def elapsed_time
    if @start_time && @end_time
      @end_time - @start_time
    else
      nil
    end
  end

  def all_resources
    @run_context && @run_context.resource_collection.all_resources
  end

  def updated_resources
    @run_context && @run_context.resource_collection.select { |r| r.updated }
  end

  def backtrace
    @exception && @exception.backtrace
  end

  def failed?
    !success?
  end

  def success?
    @exception.nil?
  end

  def to_hash
    # use a flat hash here so we can't errors from intermediate values being nil
    { :node => node,
      :success => success?,
      :start_time => start_time,
      :end_time => end_time,
      :elapsed_time => elapsed_time,
      :all_resources => all_resources,
      :updated_resources => updated_resources,
      :exception => formatted_exception,
      :backtrace => backtrace}
  end

  def formatted_exception
    @exception && "#{@exception.class.name}: #{@exception.message}"
  end

end