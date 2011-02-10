require 'rubygems'
require 'rake'

require "logger"
log = Logger.new(STDERR)

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rhook"
    gem.summary = %Q{Easily drive AOP & hacking existing library with Ruby}
    gem.description = %Q{You can provide hook point in your code, and can customize its behavior from outside. Also you can 'hack' (== injecting hook point from outside) any methods in existing code.}
    gem.email = ""
    gem.homepage = "http://github.com/kaorukobo/rhook"
    gem.authors = ["Kaoru Kobo"]
    gem.add_development_dependency "rspec", ">= 2.1.0"
    gem.add_development_dependency "yard", "~> 0.6.0"
    gem.has_rdoc = "yard"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :spec => :check_dependencies

task :default => :spec

begin
  gem "yard"
  require "yard"
  YARD::Rake::YardocTask.new do |t|
  end
rescue Gem::LoadError
  log.warn "Install YARD to generate document."
end
