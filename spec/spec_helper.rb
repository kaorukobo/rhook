require 'rubygems'
gem 'rspec', ">= 2.0"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rhook'
require "rspec"

RSpec.configure { |config|
}

local_config = File.dirname(__FILE__)+"/local_spec_config.rb"
require local_config if File.exist?(local_config)
