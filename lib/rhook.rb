module RHook
  class Registry
    attr_reader :class_cached_flag_map
    def initialize
      @class_cached_flag_map = {}
    end
  end
  
  def self.registry
    @registry ||= Registry.new
  end
  
  class RHookService
    attr_reader :hooks_map
    
    def initialize(obj)
      @obj = obj
      @hooks_map = {}
      @class_cached_hooks_map = {} if Class === @obj
    end
    
    def bind(name, opt = {}, &block)
      hook = Hook.new
      hook.hook_proc = block
       (@hooks_map[name.to_sym] ||= []).unshift( hook )
      RHook.registry.class_cached_flag_map.delete(name)
      opt[:disable] or hook.enable()
      HookGroup.add_to_current_groups(hook)
      hook
    end
    
    def hack(name, opt = {}, &block)
      if Class === @obj
        klass = @obj
        klass._rhook.on_method(name)
      end
      
      klass = @obj.instance_eval("class << self; self; end")
      klass._rhook.on_method(name)
      
      bind(name, opt, &block)
    end
    
    def unbind_all
      @hooks_map.clear
      @class_cached_hooks_map.clear
    end
    
    # nodoc:
    # Proxy class for 'to'
    class Caller
      def initialize(rhook, opt)
        @rhook = rhook
        @opt = opt
      end
      
      def method_missing(name, *args, &block)
        @rhook.call_method(name, name, args, block, @opt)
      end
    end #/Caller
    
    # ================================================================
    # Target-side methods:
    
    def to(opt = {})
      Caller.new(self, opt)
    end
    
    def call_method(name, method_name, args, block, opt = {})
      hooks = concat_hooks([], name)
      hooks.empty? and @obj.__send__(method_name, *args, &block)
      
      inv = Invocation.new
      inv.target = @obj
      inv.receiver = @obj
      inv.args = args
      inv.block = block
      inv.hooks = hooks
      inv.target_proc = @obj.method(method_name)
      inv.hint = opt[:hint] || {}
      inv.proceed()
    end
    
    def does(name, opt = {}, &block)
      hooks = concat_hooks([], name)
      hooks.empty? and return yield
      
      inv = Invocation.new
      inv.target = @obj
      inv.receiver = nil
      inv.args = []
      inv.block = nil
      inv.hooks = hooks
      inv.target_proc = block
      inv.hint = opt[:hint] || {}
      inv.proceed()
    end
    
    def on_method(*names)
      Class === @obj or raise("Cannot use on_method on non-Class.")
      code = ""
      for method_name in names
        # Skip if method is not defined.
        @obj.method_defined?(method_name) or next
        
        real_method_name = "#{method_name}__rhook_real".to_sym
        @obj.method_defined?(real_method_name) and next
        
        code << "alias #{real_method_name} #{method_name}\n"
        code << "def #{method_name}(*args, &block); _rhook.call_method(:#{method_name}, :#{real_method_name}, args, block); end\n"
      end
      @obj.module_eval(code)
    end
    
    # ================================================================
    # Internal methods:
    
    def concat_hooks(dest, name)
      if Class === @obj
        concat_class_hooks(dest, name)
      else
        concat_hooks_internal(dest, name)
        @obj.class._rhook.concat_class_hooks(dest, name)
      end
      dest
    end
    
    def concat_class_hooks(dest, name)
      # use cached one if available
      if RHook.registry.class_cached_flag_map[name]
        hooks = @class_cached_hooks_map[name]
        if hooks
          return dest.concat(hooks)
        end
      end
      
      hooks = []
      
      # collect hooks including ancestor classes
      begin
        concat_hooks_internal(hooks, name)
        
        # skips class without RHookService
        klass = @obj
        while klass
          if klass._has_rhook?
            klass._rhook.conact_class_hooks(hooks, name)
            break
          end
          klass = klass.superclass
        end
      end
      
      # Store to cache. 
      @class_cached_hooks_map[name] = hooks
      RHook.registry.class_cached_flag_map[name] = true
      
      dest.concat(hooks)
    end
    
    def concat_hooks_internal(dest, name)
      hooks = @hooks_map[name]
      hooks and dest.concat(hooks)
    end
  end #/RHookService
  
  class Invocation < Struct.new(:target, :receiver, :args, :block, :returned, :hooks, :target_proc, :hint)
    def initialize
      @hook_index = 0
    end
    
    def proceed
      hook = hooks[@hook_index]
      # -- If no more hook was found, calls target procedure and return
      hook or return target_proc.call(*args, &block)
      # -- Set hook pointer to next, then call next hook
      @hook_index += 1
      begin
        hook.call(self)
      ensure
        @hook_index -= 1
      end
    end
    
    alias call proceed
  end #/Invocation
  
  class Hook
    attr_accessor :enabled
    attr_accessor :hook_proc
    
    def call(inv)
      @enabled or return inv.proceed()
      hook_proc.call(inv)
    end
    
    def enable(&block)
      @enabled = true
      if block_given?
        begin
          return yield
        ensure
          @enabled = false
        end
      end
      self
    end
    
    def disable
      @enabled = false
      self
    end
  end #/Hook
  
  class ::Object
    def _rhook
      @_rhook ||= RHook::RHookService.new(self)
    end
    
    def _has_rhook?
      @rhook ? true : false
    end
  end
  
  class HookGroup
    def initialize
      @hooks = []
    end
    
    def add(hook)
      @hooks << hook
    end
    
    def wrap(&block)
      group_stack = (Thread.current["rhook_group"] ||= [])
      group_stack << self 
      begin
        yield
      ensure
        group_stack.pop
      end
      self
    end
    
    def enable(&block)
      @hooks.each do |h|
        h.enable
      end
      if block_given?
        begin
          return yield
        ensure
          disable
        end
      end
      self
    end
    
    def disable
      @hooks.each do |h|
        h.disable
      end
      self
    end
    
    def self.add_to_current_groups(hook)
      (Thread.current["rhook_group"] || []).each do |group|
        group.add(hook)
      end
    end
  end #/HookGroup
  
  def self.group(&block)
    HookGroup.new.wrap(&block)
  end
end
