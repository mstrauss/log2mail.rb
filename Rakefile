require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

require 'rake/notes/rake_task'

task :default => [:spec, :features, :man]

desc 'Build the manual'
task :man do
  require 'ronn'
  sh "ronn -w -s toc -r5 --markdown man/*.ronn"
  FileUtils.mv("man/log2mail.1.markdown", "README.md")
end
