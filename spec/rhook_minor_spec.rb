require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# ================================================================
describe "rhook (minor specifications / behavior, and bugs)" do
  class Target
    
  end
  
  before :each do
    Target._rhook.unbind_all()
  end
  
  # ================================================================
  describe "invocation" do
    describe "is proceed by correct order & not rerun." do
      class Target
        attr_reader :order_ary
        def order_call
          @order_ary = []
          _rhook.to.order_target
        end
        
        def order_target
          @order_ary << "orig"
        end
      end
      
      example do
        t = Target.new
        
        # [bug] It calls the target method/procedure twice when no hooks are registered.
        t.order_call
        t.order_ary.should == ["orig"]
        
        t._rhook.bind(:order_target) do |inv|
          t.order_ary << "before_call"
          inv.call
          t.order_ary << "after_call"
        end
        t.order_call
        t.order_ary.should == ["before_call", "orig", "after_call"]
      end
    end
  end
  
  # ================================================================
  describe "hack" do
    # ================================================================
    describe "Can hack on private method" do 
      class Target
        def call_private
          test_private
        end
        
        private
        def test_private
        "foo"
        end
      end #/Target
      
      example do
        Target._rhook.hack(:test_private) do |inv|
        "bar"
        end
        t = Target.new
        t.call_private.should == "bar"
      end
    end 
    # ================================================================
    
    # ================================================================
    describe "Raises error on hack to non-existent method" do
      class Target
        def hack_err1
        end
        
        def self.hack_err2
        end
      end
      
      example do
        Target._rhook.hack(:hack_err1) do |inv|
          
        end
        Target._rhook.hack(:hack_err2) do |inv|
          
        end
        proc {
          Target._rhook.hack(:hack_err_nonexistent_method) do |inv|
            
          end
        }.should raise_error(/defined in neither/)
      end
    end
  end
  
  # ================================================================
  describe "on_method" do
    # ================================================================
    describe "to non-existent method" do
      
      class Target
        def on_method_test_non_existent
          
        end
      end
      
      example "raises error" do
        proc {
          Target._rhook.on_method(:nonexistent_method)
        }.should raise_error(/Tried to on_method/)
      end
      
      example "to ignore error, set :ifdef => true" do
        result = Target._rhook.on_method(:nonexistent_method, :ifdef => true)
        result.should == false
        
        # if success, it returns true
        result = Target._rhook.on_method(:on_method_test_non_existent, :ifdef => true)
        result.should == true
      end
      
    end
    
    # ========================================================================
    describe "is applied to the method (== 'hack'ed), and also it is called via _rhook.to(), " do
      class Target
        def both_on_method_and_to
          _rhook.to.both_on_method_and_to_target
        end
        
        def both_on_method_and_to_target
          
        end
      end
      
      example "even though, the hook should be just called once." do
        m = mock
        m.should_receive(:called).once
        
        Target._rhook.hack(:both_on_method_and_to_target) { |inv|
          m.called
          inv.call
        } 
        Target.new.both_on_method_and_to()
      end
    end
  end
  
  # ========================================================================
  describe "#call_method(#to): " do
    before :each do
    end
    
    example "[bugfix] super: no superclass method" do
      class CallMethodSuperTest_Super
        def the_method
          
        end
      end
      
      module CallMethodSuperTest_Module
        def the_method
          super
        end
      end
      
      class CallMethodSuperTest_Inherited < CallMethodSuperTest_Super
        include CallMethodSuperTest_Module
      end
      
      # This bug does not appear without hooks.
      CallMethodSuperTest_Inherited._rhook.bind(:the_method) do |inv|
        inv.call
      end
      
      # OK.
      CallMethodSuperTest_Inherited.new.the_method
      
      # We fixed the bug this cause error:
      lambda {
        CallMethodSuperTest_Inherited.new._rhook.to.the_method
      }.should_not raise_error
      # - super: no superclass method `the_method'
    end
  end
  # ========================================================================
  
end