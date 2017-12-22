#
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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

desc "Tasks to update and check dependencies"
namespace :dependencies do

  # Running update_ci on your local system wont' work. The best way to update
  # dependencies locally is by running the dependency update script.
  desc "Update all dependencies. dependencies:update to update as little as possible."
  task :update do |t, rake_args|
    # FIXME: probably broken, and needs less indirection
    system("#{File.join(Dir.pwd, "ci", "dependency_update.sh")}")
  end

  desc "Force update (when adding new gems to Gemfiles)"
  task :force_update do |t, rake_args|
    # FIXME: probably broken, and needs less indirection
    FileUtils.rm_f(File.join(Dir.pwd, ".bundle", "config"))
    system("#{File.join(Dir.pwd, "ci", "dependency_update.sh")}")
  end

  # Update all dependencies to the latest constraint-matching version
  desc "Update all dependencies. dependencies:update to update as little as possible (CI-only)."
  task :update_ci => %w{
                    dependencies:update_gemfile_lock
                    dependencies:update_omnibus_gemfile_lock
                    dependencies:update_acceptance_gemfile_lock
                    dependencies:update_audit_tests_berksfile_lock
                  }

  def bundle_update_locked_multiplatform_task(task_name, dir)
    desc "Update #{dir}/Gemfile.lock."
    task task_name do
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

  def berks_update_task(task_name, dir)
    desc "Update #{dir}/Berksfile.lock."
    task task_name do
      FileUtils.rm_f("#{dir}/Berksfile.lock")
      Dir.chdir(dir) do
        Bundler.with_clean_env do
          sh "bundle exec berks install"
        end
      end
    end
  end

  bundle_update_locked_multiplatform_task :update_gemfile_lock, "."
  bundle_update_locked_multiplatform_task :update_omnibus_gemfile_lock, "omnibus"
  bundle_update_task :update_acceptance_gemfile_lock, "acceptance"
  berks_update_task :update_audit_tests_berksfile_lock, "kitchen-tests/cookbooks/audit_test"

end

desc "Update all dependencies and check for outdated gems."
task :dependencies_ci => [ "dependencies:update_ci" ]
task :dependencies => [ "dependencies:update" ]
task :update => [ "dependencies:update" ]
