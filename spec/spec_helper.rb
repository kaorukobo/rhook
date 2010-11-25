require 'rubygems'
gem 'rspec', "< 2.0"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rhook'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

# ========================================================================
# Defines custom matcher to test the hook was called.

module ::Spec::Matchers
  class HookCalledMatcher
    def initialize(opt)
      @times = opt[:times]
      @count = 0
    end
    
    def yes
      @count += 1
    end
    
    def matches?(block)
      block.call(self)
      if @times
        begin
          @count.should == @times
        rescue
          @times_msg = " (Exactly called count: #{$!})"
          false
        end
      else
        @count > 0
      end
    end
    
    def failure_message
      "Expected the hook to be called.#{@times_msg}"
    end
    
    def negative_failure_message
      "Expected the hook not to be called.#{@times_msg}"
    end
  end
  
  def calls_hook(opt = {})
    HookCalledMatcher.new(opt)
  end
end
