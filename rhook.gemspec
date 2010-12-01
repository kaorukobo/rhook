# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rhook}
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaoru Kobo"]
  s.date = %q{2010-11-25}
  s.description = %q{You can provide hook point in your code, and can customize its behavior from outside. Also you can 'hack' (== injecting hook point from outside) any methods in existing code.}
  s.email = %q{}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".yardopts",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/rhook.rb",
    "rhook.gemspec",
    "spec/examples/log_buffer_example_spec.rb",
    "spec/rhook_minor_spec.rb",
    "spec/rhook_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/kaorukobo/rhook}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Easily drive AOP & hacking existing library with Ruby}
  s.test_files = [
    "spec/examples/log_buffer_example_spec.rb",
    "spec/rhook_minor_spec.rb",
    "spec/rhook_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

