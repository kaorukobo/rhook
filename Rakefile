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
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", "~> 0.6.0"
    gem.has_rdoc = "yard"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
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
