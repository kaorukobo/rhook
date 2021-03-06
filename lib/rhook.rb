module RHook
  # @private
  # The registry contains information globally shared. (like cache)
  # You don't need to use this class.
  class Registry
    attr_reader :class_cached_flag_map
    def initialize
      @class_cached_flag_map = {}
    end
  end
  
  # @private
  # Get global +Registry+ object.
  def self.registry
    @registry ||= Registry.new
  end
  
  # Most important class on rhook.
  # 
  # If you call obj._rhook, it returns a RHookService object bound to +obj+. 
  class RHookService
    # @private
    attr_reader :hooks_map
    # @private
    attr_accessor :last_name_call_method_done
    
    # @private
    def initialize(obj)
      @obj = obj
      @hooks_map = {}
      @class_cached_hooks_map = {} if Class === @obj
    end
    
    # Returns the object bound to this RHookService.
    # ( +obj+ of +obj._rhook+ ) 
    def bound_object
      @obj
    end
    
    # ========================================================================
    # @group Methods for hook-side(outside)
    # ========================================================================

    # Add hook to the {#bound_object}. If it is a kind of Class, the hook is affected to all instance & subclasses of the class.
    # 
    # @param [Symbol] name hook-point's name (commonly equals to method name)
    # @option opt [true] :disable Creates hook but make disabled. (by default, automatically enabled.)
    # @option opt [RHook::HookGroup] :group Adds itself into the specified hook-group.
    # @option opt [Symbol] :once Binds the given hook only once. (give a key to identify this hook. See rhook_minor_spec.rb)
    # @yield [inv] The hook block.
    # @yieldparam [Invocation] inv
    # @yieldreturn The result value. (Returned value of called method.)
    # @return [Hook] Created hook.
    def bind(name, opt = {}, &block)
      name = name.to_sym
      hook = Hook.new
      hook.hook_proc = block
      hook.bound_info = [self, name]
      array = (@hooks_map[name] ||= [])
      
      once_key = opt[:once]
      if once_key
        existing_hook = array.find { |hk|
          hk.once_key == once_key
        }
        existing_hook and return existing_hook
        hook.once_key = once_key
      end
      array.unshift( hook )
      RHook.registry.class_cached_flag_map.delete(name)
      opt[:disable] or hook.enable()
      if opt[:group]
        opt[:group].add(hook)
      else
        HookGroup.add_to_current_groups(hook)
      end
      hook
    end
    
    # Injects hook-point (hack) to the paticular method in {#bound_object}, and add hook same as {#bind}.
    #
    # The hook-point injection is done by 'alias' method.
    # If the hook-point is already injected, this just does {#bind}.
    #
    # @param [Symbol] name    The name of method to hack.
    # @yield [inv]
    # @return [Hook]
    # @see #bind See #bind for other param/return.
    def hack(name, opt = {}, &block)
      success = false
      if Class === @obj
        klass = @obj
        success |= klass._rhook.on_method(name, :ifdef => true)
      end
      
      klass = @obj.instance_eval("class << self; self; end")
      success |= klass._rhook.on_method(name, :ifdef => true)
      
      success or raise(NameError, "Method #{name} is defined in neither class nor object-specific class.")
      
      bind(name, opt, &block)
    end
    
    # @group Methods for hook-side(outside)
    # 
    # Unbind all hooks bound to {#bound_object}.
    # @return [self]
    def unbind_all
      @hooks_map.clear
      @class_cached_hooks_map.clear
      self
    end
    
    # @group Methods for hook-side(outside)
    # 
    # Unbind the bound hook on {#bound_object}. (Not commonly used, use {RHook::Hook#unbind}.)
    # @return [self]
    def unbind(name, hook_object)
      name = name.to_sym
      array = @hooks_map[name] or return
      array.delete(hook_object)
      RHook.registry.class_cached_flag_map.delete(name)
      self
    end
    
    # ========================================================================
    # @endgroup
    # ========================================================================

    # @private
    class Caller
      def initialize(rhook, opt)
        @rhook = rhook
        @opt = opt
      end
      
      def method_missing(name, *args, &block)
        @rhook.call_method(name, name, args, block, @opt)
      end
    end #/Caller
    
    # ========================================================================
    # @group Methods for target-side (for providing hook-point)
    # ========================================================================

    # Wraps {#bound_object}'s method call to be hookable.
    #
    # @example 
    #   _rhook.to.method_name(arg1, arg2)
    #
    # @option opt [Hash] :hint Hint values used through {Invocation#hint}.
    # @return Proxy to call method.
    def to(opt = {})
      Caller.new(self, opt)
    end
    
    # @private
    # Used in call_method
    # Instead of ''lambda { |*args, &block| @obj.__send__(method_name, *args, &block); }''
    # because some earlier versions of Ruby-1.8 cannot parse it.
    class MethodCaller
      def initialize(obj, method_name)
        @obj = obj
        @method_name = method_name
      end
      
      def call(*args, &block)
        @obj.__send__(@method_name, *args, &block)
      end
    end #/MethodCaller
    
    # @private
    def call_method(name, method_name, args, block, opt = {})
      if @last_name_call_method_done == name
        return @obj.__send__(method_name, *args, &block)
      end
      @last_name_call_method_done = name
      
      hooks = concat_hooks([], name)
      hooks.empty? and return @obj.__send__(method_name, *args, &block)
      
      inv = Invocation.new
      inv.target = @obj
      inv.receiver = @obj
      inv.name = name
      inv.args = args
      inv.block = block
      inv.hooks = hooks
      inv.target_proc = MethodCaller.new(@obj, method_name)
      inv.hint = opt[:hint] || {}
      inv.proceed()
    ensure
      @last_name_call_method_done = nil
    end
    
    # Wraps the code block to be hookable.
    #
    # @example
    #   _rhook.does(:hook_name) { do_something; }
    #
    # @param [Symbol] name The hook-point's name specified on {#bind}.
    # @option opt [Hash] :hint Hint values used through {Invocation#hint}.
    # @yield The code block to be hooked.
    # @return The result of code block. (Replaced if it is changed by hook.)
    def does(name, opt = {}, &block)
      hooks = concat_hooks([], name)
      hooks.empty? and return yield
      
      inv = Invocation.new
      inv.target = @obj
      inv.receiver = nil
      inv.name = name
      inv.args = []
      inv.block = nil
      inv.hooks = hooks
      inv.target_proc = block
      inv.hint = opt[:hint] || {}
      inv.proceed()
    end
    
    # Wraps the defined method to be hookable.
    # 
    # If possible, using {#to} is recommended than {#on_method}, because if the subclass override the hookable method, the subclasse's code become out of hook target.
    #
    # @example
    #   on_method :method_name
    #
    # @overload on_method(*names, opt = {})
    #   @param [Symbol] names The method name(s).
    #   @option opt [Boolean] :ifdef If true, it doesn't raise error whenever the method is not defined.
    # @raise [NameError] If the method is not defined.
    # @return [Boolean] When :ifdef => true, returns sucess or not, otherwise always true.
    def on_method(*names_and_opt)
      success = true
      
      names = names_and_opt
      Class === @obj or raise("Cannot use on_method on non-Class.")
      opt = (Hash === names[-1]) ? names.pop : {}
      for method_name in names
        real_method_name = "#{method_name}__rhook_real".to_sym
        @obj.method_defined?(real_method_name) and next
        
        begin
          @obj.module_eval "alias #{real_method_name} #{method_name}", __FILE__, __LINE__
        rescue NameError
          # When method_is not defined:
          opt[:ifdef] and (success = false; next)
          raise NameError, "[Tried to on_method for undefined method] #{$!}"
        end
        @obj.module_eval "def #{method_name}(*args, &block); _rhook.call_method(:#{method_name}, :#{real_method_name}, args, block); end", __FILE__, __LINE__
      end
      
      success
    end
    
    # ========================================================================
    # @endgroup
    # ========================================================================

    # @private
    def concat_hooks(dest, name)
      if Class === @obj
        concat_class_hooks(dest, name)
      else
        concat_hooks_internal(dest, name)
        @obj.class._rhook.concat_class_hooks(dest, name)
      end
      dest
    end
    
    # @private
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
        while true
          klass = klass.superclass
          klass or break
          if klass._has_rhook?
            klass._rhook.concat_class_hooks(hooks, name)
            break
          end
        end
      end
      
      # Store to cache. 
      @class_cached_hooks_map[name] = hooks
      RHook.registry.class_cached_flag_map[name] = true
      dest.concat(hooks)
    end
    
    # @private
    def concat_hooks_internal(dest, name)
      hooks = @hooks_map[name]
      hooks and dest.concat(hooks)
    end
    
    # @private
    def inspect
      "#<#{self.class}>"
    end
  end #/RHookService
  
  # The object contains the invocation information.
  #
  # @attr_reader [Object] target The target object that the hook is applied. (Usually same to {#receiver})
  # @attr_reader [Object] receiver The receiver object of this method invocation.
  # @attr [Array<Object>] args The arguments given to the method invocation. 
  # @attr [Proc] block The block given to the method invocation
  # @attr_reader [Object] returned The returned value by the method invocation. (Don't set this. To change it, just return by the alternative value from the hook procedure.) 
  # @attr_reader [Array<Hook>] hooks (Internally used) The applied hooks on this invocation.
  # @attr [Proc] target_proc (Internally used) The procedure to execute the target method/procedure.
  # @attr [Hash] hint Hint data given by {RHookService#does} / {RHookService#to}.
  class Invocation < Struct.new(:target, :receiver, :name, :args, :block, :returned, :hooks, :target_proc, :hint)
    # @private
    def initialize
      @hook_index = 0
    end
    
    # Proceed to execute the next one on hooks-chain. If no more hooks, execute the target method/procedure.
    # @return The returned value from the target method/procedure. (may changed by hook)
    def proceed
      hook = hooks[@hook_index]
      # -- If no more hook was found, calls target procedure and return
      hook or return self.returned = target_proc.call(*args, &block)
      # -- Set hook pointer to next, then call next hook
      @hook_index += 1
      begin
        self.returned = hook.call(self)
      ensure
        @hook_index -= 1
      end
    end
    
    alias call proceed
  end #/Invocation
  
  # The registered hook instance returned by #{RHookService#bind}.
  class Hook
    # Whether this hook is enabled.
    # @return [Boolean] 
    attr_accessor :enabled
    # The hook procedure registered by {RHookService#bind}.
    # @return [Proc] 
    attr_accessor :hook_proc
    # @private
    attr_accessor :bound_info
    # @private
    attr_accessor :once_key
    
    # @private
    def call(inv)
      @enabled or return inv.proceed()
      hook_proc.call(inv)
    end
    
    # Enable this hook.
    # @overload enable()
    # @overload enable(&block)
    # @yield If block was given, the hook is enabled only within the given code block. (Note: This is not thread-safe.)
    # @return [self]
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
    
    # Disable this hook.
    # @return [self]
    def disable
      @enabled = false
      self
    end
    
    # Unbind this hook.
    # @return [self]
    def unbind
      service, name = @bound_info
      service.unbind(name, self)
      self
    end
    
    # After executing block, do {#unbind}.
    # @return nil (Should return either self or block's result...?)
    def within(&block)
      begin
        yield
      ensure
        unbind
      end
      nil
    end
  end #/Hook
  
  # 
  class ::Object
    # Get {RHook::RHookService} object bound to this object.
    # @return [RHook::RHookService]
    def _rhook
      @_rhook ||= RHook::RHookService.new(self)
    end
    
    # @private
    def _has_rhook?
      @_rhook ? true : false
    end
  end
  
  # Object to group the hooks for the certain purpose.
  # You can enable/disable the grouped hooks at once.
  #
  # Don't instantiate this class. Use {RHook.group} method.
  class HookGroup
    # @private
    def initialize
      @hooks = []
    end
    
    # Add a new hook to this group.
    # @return [self]
    def add(hook)
      @hooks << hook
      self
    end
    
    # Add any hooks to this group that was registered by #{RHookService#bind} in the given block code.
    # @return [self]
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
    
    # Enable the hooks.
    # @return [self]
    # @see Hook#enable
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
    
    # Disable the hooks.
    # @return [self]
    # @see Hook#disable
    def disable
      @hooks.each do |h|
        h.disable
      end
      self
    end
    
    # Unbind the hooks.
    # @return [self]
    # @see Hook#unbind
    def unbind
      @hooks.each do |h|
        h.unbind
      end
      self
    end
    
    # After executing block, do {#unbind}.
    # @return nil (Should return either self or block's result...?)
    def within(&block)
      begin
        yield
      ensure
        unbind
      end
      nil
    end
    
    # Tests the given hook is registered in this group.
    # @return [Boolean]
    def include?(hook)
      @hooks.include?(hook)
    end
    
    # @private
    def self.add_to_current_groups(hook)
     (Thread.current["rhook_group"] || []).each do |group|
        group.add(hook)
      end
    end
  end #/HookGroup
  
  # Create the {HookGroup}, and add any hooks to this group that was registered by #{RHookService#bind} in the given block code.
  # 
  # @example
  #   XXX_feature_for_library = RHook.group {
  #     Target._rhook.bind(...) {...}
  #     Target2._rhook.bind(...) {...}
  #   }
  #   XXX_feature_for_library.disable
  # 
  # @example
  #   grp = RHook.group
  #   Target._rhook.bind(..., :group => grp) { ... }
  #
  # @return [HookGroup]
  def self.group(&block)
    group = HookGroup.new
    block and group.wrap(&block)
    group
  end

  # Return the hook procedure to trace information about method invocation.
  #
  # @option opt [String,Symbol] :tag Append prefix [tag] (default: 'trace')
  # @option opt [Array] :caller_range Specify [BEGIN, COUNT_OF_LOCATIONS] -> Prints COUNT_OF_LOCATIONS caller locations from caller(BEGIN) (default: RHook::TRACER_CALLER_RANGE_DEFAULT)
  # @return [Proc]
  # @example
  #   TheClass._rhook.hack(:the_method, &RHook.tracer)
  def self.tracer(opt = {})
    require "rhook/tracer"
    tracer_impl(opt)
  end

  class << self
    attr_accessor :trace_printer
  end
  self.trace_printer = lambda { |msg| $stderr.print(msg); }
end
