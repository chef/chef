#
# Copyright:: Copyright (c) 2016-2018, Chef Software Inc.
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

require "bundler"

desc "Tasks to update and check dependencies"
namespace :dependencies do
  # Update all dependencies to the latest constraint-matching version
  desc "Update all dependencies."
  task update: %w{
                    dependencies:update_gemfile_lock
                    dependencies:update_omnibus_gemfile_lock
                  }

  def bundle_update_locked_multiplatform_task(task_name, dir)
    desc "Update #{dir}/Gemfile.lock."
    task task_name do
      # make sure we execute this upgrade with the correct bundler version. Otherwise the bundler version
      # in the lock file we be updated in an incompatible way. Bundler 2.1 *may* fix this issue for us.
      bundler_version = `grep bundler omnibus_overrides.rb | cut -d'"' -f2`
      gem "bundler", "~> #{bundler_version}"
      
      Dir.chdir(dir) do
        Bundler.with_clean_env do
          rm_f "#{dir}/Gemfile.lock"
          sh "bundle lock --update --add-platform ruby"
          sh "bundle lock --update --add-platform x64-mingw32"
          sh "bundle lock --update --add-platform x86-mingw32"
        end
      end
    end
  end

  def bundle_update_task(task_name, dir)
    desc "Update #{dir}/Gemfile.lock."
    task task_name do
      Dir.chdir(dir) do
        Bundler.with_clean_env do
          sh "bundle update"
        end
      end
    end
  end

  bundle_update_locked_multiplatform_task :update_gemfile_lock, "."
  bundle_update_locked_multiplatform_task :update_omnibus_gemfile_lock, "omnibus"
end
