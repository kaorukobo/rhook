require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# ================================================================
describe "rhook (basic usage)" do
  class TargetBasic
    def greeting
      my_name = _rhook.does(:my_name) { "Mike"; }
      your_name = "Dan"
      _rhook.to.hello(your_name) + "I am #{my_name}."
    end
    
    def hello(name)
      "Hello, #{name}. "
    end
  end #/TargetBasic
  
  before :each do
    TargetBasic._rhook.unbind_all()
  end
  
  example "without any hook" do
    t = TargetBasic.new
    t.greeting.should == "Hello, Dan. I am Mike."
  end
  
  example "bind to object" do
    t = TargetBasic.new
    t._rhook.bind(:hello) { |inv|
      inv.args[0] = "Jenkins"
      inv.call
    }
    t.greeting.should == "Hello, Jenkins. I am Mike."
  end
  
  example "bind to all instances of class" do
    t = TargetBasic.new
    TargetBasic._rhook.bind(:hello) { |inv|
      inv.args[0] = "Jenkins"
      inv.call
    }
    t.greeting.should == "Hello, Jenkins. I am Mike."
  end
  
  example "does(NAME) {}" do
    t = TargetBasic.new
    TargetBasic._rhook.bind(:my_name) { |inv|
      "Katherine"
    }
    t.greeting.should == "Hello, Dan. I am Katherine."
  end
end

# ================================================================
describe "rhook (advanced usage)" do
  class Target
    
  end
  
  before :each do
    Target._rhook.unbind_all()
  end
  
  # ================================================================
  describe "on_method" do 
    class Target
      def test__on_method()
      "foo"
      end
      _rhook.on_method :test__on_method
    end #/Target
    
    example "Hook on any method call: on_method" do
      # not recommanded.
      
      t = Target.new
      t._rhook.bind(:test__on_method) do |inv|
        inv.call + "&bar"
      end
      t.test__on_method.should == "foo&bar"
    end
  end 
  # ================================================================
  
  # ================================================================
  describe "Hack" do
    class Target
      def test__hack()
      "foo"
      end
    end #/Target
    
    example "Hack on object" do
      t = Target.new
      t._rhook.hack(:test__hack) do |inv|
      "bar"
      end
      t.test__hack.should == "bar"
      t2 = Target.new
      t2.test__hack.should == "foo"
    end
    
    example "Hack on class" do
      t = Target.new
      Target._rhook.hack(:test__hack) do |inv|
      "bar"
      end
      t.test__hack.should == "bar"
      t2 = Target.new
      t2.test__hack.should == "bar"
    end
    
    class Target
      def self.hack_class_method
      "foo"
      end
    end #/Target
    
    example "Hack on class method" do
      Target._rhook.hack(:hack_class_method) do |inv|
      "bar"
      end
      Target.hack_class_method.should == "bar"
    end
  end
  # ================================================================
  
  
  # ================================================================
  describe "Hook object (enable/disable)" do
    class Target
      def enable_disable()
        "disabled"
      end
    end #/Target
    
    example do
      hook = Target._rhook.hack(:enable_disable) do |inv|
        "enabled"
      end
      
      t = Target.new
      t.enable_disable.should == "enabled"
      
      hook.disable
      t.enable_disable.should == "disabled"
      
      # with block
      hook.enable do
        t.enable_disable.should == "enabled"
      end
      t.enable_disable.should == "disabled"
    end
  end
  
  
  # ================================================================
  describe "Hook group" do
    class Target
      def group_1
        "g1"
      end
      
      def group_2
        "g2"
      end
    end
    
    example "group and enable/disable by group." do
      group = RHook.group do
        Target._rhook.hack(:group_1) do |inv|
          "hack1"
        end
        Target._rhook.hack(:group_2) do |inv|
          "hack2"
        end
      end
      
      t = Target.new
      group.disable
      t.group_1.should == "g1"
      t.group_2.should == "g2"
      group.enable do
        t.group_1.should == "hack1"
        t.group_2.should == "hack2"
      end
      t.group_1.should == "g1"
      t.group_2.should == "g2"
    end
    
    example "Nested group" do
      @parent_group = RHook.group do
        Target._rhook.hack(:group_1) do |inv|
          "hack1"
        end
        @child_group = RHook.group do
          Target._rhook.hack(:group_2) do |inv|
            "hack2"
          end
        end
      end
      
      t = Target.new
      
      @parent_group.disable
      t.group_1.should == "g1"
      t.group_2.should == "g2"
      
      @child_group.enable      
      t.group_1.should == "g1"
      t.group_2.should == "hack2"
      
      @parent_group.enable
      t.group_1.should == "hack1"
      t.group_2.should == "hack2"
    end
    
    example "Adding a hook to group with bind()'s :group option." do
      # Instantiate a group with RHook.group() without block.
      group = RHook.group
      t = Target.new
      hook = t._rhook.hack(:group_1, :group => group) do |inv|
        inv.call
      end
      group.include?(hook).should be_true
    end
  end
  # ================================================================
  
  # ========================================================================
  describe "Invocation object" do
    class Target
      def invocation_object(*args, &block)
        _rhook.to(:hint => {:hintkey => :hintval}).invocation_object_target(*args, &block)
      end
      
      def invocation_object_target(*args, &block)
        :returned_value
      end
    end #/Target
    
    example "attributes" do
      args = [1, 2]
      block = lambda do
        
      end
      
      m = mock
      m.should_receive(:second).once.ordered
      m.should_receive(:first).once.ordered
      
      t = Target.new
      t._rhook.bind(:invocation_object_target) { |inv|
        # first hook
        m.first
        inv.call()
        inv.returned.should == :returned_value
          :returned_value_hooked
      }
      t._rhook.bind(:invocation_object_target) { |inv|
        # second hook
        m.second
        inv.args.should == args
        inv.block.should == block
        inv.hint[:hintkey].should == :hintval
        inv.receiver.should == t
        inv.target.should == t
        inv.returned.should be_nil
        inv.call()
        inv.returned.should == :returned_value_hooked
      }
      t.invocation_object(*args, &block)
    end
  end
  # ========================================================================
  
end

# ================================================================
describe "rhook (behavior)" do
  # ================================================================
  describe "Super class's hook" do
    class Target
    end
    
    class ChildTarget < Target
      def superclass_test
        _rhook.does(:superclass_test) { "foo"; }
      end
    end
    
    example "Super class's hook affects children class." do
      child_t = ChildTarget.new
      child_t.superclass_test.should == "foo"
      # Add hook to superclass:
      Target._rhook.bind(:superclass_test) do |inv|
        "bar"
      end
      # then it affects to children class:
      child_t.superclass_test.should == "bar"
    end
  end
  
  # ================================================================
  describe "multiple (chained) hooks" do
    class Target
      def chained
        ["original"]
      end
    end
    
    example "multiple hooks" do
      t = Target.new
      t._rhook.hack(:chained) do |inv|
        inv.call + ["1st_hook"]
      end
      t._rhook.hack(:chained) do |inv|
        inv.call + ["2nd_hook"]
      end
      
      t.chained.should == ["original", "1st_hook", "2nd_hook"]
    end
    
    example "Hook to class is executed later, than one to object" do
      t = Target.new
      t._rhook.hack(:chained) do |inv|
        inv.call + ["object_hook"]
      end
      Target._rhook.hack(:chained) do |inv|
        inv.call + ["class_hook"]
      end
      
      t.chained.should == ["original", "class_hook", "object_hook"]
    end
  end
  
  
  
end
