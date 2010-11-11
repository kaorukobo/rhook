require 'rubygems'
gem 'rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rhook'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end
