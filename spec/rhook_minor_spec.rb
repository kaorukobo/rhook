require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# ================================================================
describe "rhook (minor specifications / behavior, and bugs)" do
  class Target
    
  end
  
  before :each do
    Target._rhook.unbind_all()
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
  end
end