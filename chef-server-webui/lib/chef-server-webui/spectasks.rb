namespace :slices do
  namespace :chefserverslice do

    desc "Run slice specs within the host application context"
    task :spec => [ "spec:explain", "spec:default" ]

    namespace :spec do

      slice_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

      task :explain do
        puts "\nNote: By running ChefServerWebui specs inside the application context any\n" +
             "overrides could break existing specs. This isn't always a problem,\n" +
             "especially in the case of views. Use these spec tasks to check how\n" +
             "well your application conforms to the original slice implementation."
      end

      Spec::Rake::SpecTask.new('default') do |t|
        t.spec_opts = ["--format", "specdoc", "--colour"]
        t.spec_files = Dir["#{slice_root}/spec/**/*_spec.rb"].sort
      end

      desc "Run all model specs, run a spec for a specific Model with MODEL=MyModel"
      Spec::Rake::SpecTask.new('model') do |t|
        t.spec_opts = ["--format", "specdoc", "--colour"]
        if(ENV['MODEL'])
          t.spec_files = Dir["#{slice_root}/spec/models/**/#{ENV['MODEL']}_spec.rb"].sort
        else
          t.spec_files = Dir["#{slice_root}/spec/models/**/*_spec.rb"].sort
        end
      end

      desc "Run all request specs, run a spec for a specific request with REQUEST=MyRequest"
      Spec::Rake::SpecTask.new('request') do |t|
        t.spec_opts = ["--format", "specdoc", "--colour"]
        if(ENV['REQUEST'])
          t.spec_files = Dir["#{slice_root}/spec/requests/**/#{ENV['REQUEST']}_spec.rb"].sort
        else
          t.spec_files = Dir["#{slice_root}/spec/requests/**/*_spec.rb"].sort
        end
      end

      desc "Run all specs and output the result in html"
      Spec::Rake::SpecTask.new('html') do |t|
        t.spec_opts = ["--format", "html"]
        t.libs = ['lib', 'server/lib' ]
        t.spec_files = Dir["#{slice_root}/spec/**/*_spec.rb"].sort
      end

    end

  end
end
