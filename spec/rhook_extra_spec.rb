require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# ================================================================
describe "rhook (extra function)" do
  # ========================================================================
  describe "tracer" do
    before :each do
      @msgs = []
      RHook.trace_printer = lambda do |msg|
        @msgs << msg
      end
    end
    
    class Target
      def self.target(arg)
        arg + 1
      end
    end
    
    example do
      Target._rhook.hack(:target, &RHook.tracer)
      # add another hook.
      Target._rhook.hack(:target) do |inv|
        inv.call
      end
      Target.target(1).should == 2; caller_line = __LINE__
      
      # to confirm with eye:
      # puts @msgs
      
      # starts with call information
      msg = @msgs.shift
      msg.should match(/:args=>\[1\]/)
      
      # ends with return information
      msg = @msgs.pop
      msg.should match(/:returned=>2/)

      # after call information, the caller location should be printed.
      msg = @msgs.join("\n")
      msg.should match(/#{File.basename(__FILE__)}:#{caller_line}/)
    end
  end
  # ========================================================================
  
end