#
# Copyright:: Copyright 2017 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

task :ci_version_bump do
  begin
    require "rake"

    Rake::Task["version:bump_patch"].invoke
    Rake::Task["version:update"].invoke

    # We want to log errors that occur in the following tasks, but we don't
    # want them to stop an otherwise valid version bump from progressing.
    begin
      Rake::Task["changelog:update"].invoke
    rescue Exception => e
      puts "There was an error updating the CHANGELOG"
      puts e
    end

    begin
      Rake::Task["update_dockerfile"].invoke
    rescue Exception => e
      puts "There was an error updating the Dockerfile"
      puts e
    end
  end
end
