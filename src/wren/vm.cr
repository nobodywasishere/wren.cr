module Wren
  alias Value = String | Bool | Float64 | Nil

  class VM
    # :nodoc:
    getter _vm : Pointer(LibWren::Vm)

    getter config : Config

    def initialize(@config = Config.new)
      @_vm = LibWren.new_vm(@config._config_ptr)

      config.user_data.vm = WeakRef.new(self)
    end

    def finalize
      # Potential circular dependency, need to remove
      config.user_data.vm = nil

      LibWren.free_vm(_vm)

      config.user_data.call_handles.each do |_, handle|
        LibWren.release_handle(_vm, handle)
      end

      config.user_data.slot_handles.each do |_, handle|
        LibWren.release_handle(_vm, handle)
      end

      config.user_data.method_bindings = MethodBindings.new
      config.user_data.class_bindings = ClassBindings.new

      GC.free(config.user_data.module_dirs.as(Void*))
      GC.free(config.user_data.as(Void*))
      GC.free(config.as(Void*))
      GC.free(self.as(Void*))
    end

    def interpret(mod : String = "main", & : Proc(String)) : LibWren::InterpretResult
      script = yield
      interpret(script, mod)
    end

    def interpret(script : String, mod : String = "main") : LibWren::InterpretResult
      LibWren.interpret(_vm, mod.to_unsafe, script.to_unsafe)
    end

    def bind_method(klass : String, static? : Bool, signature : String, mod : String = "main", &block : LibWren::ForeignMethodFn)
      raise "#{mod}.#{klass}.#{static?}.#{signature}: Bound method can't have closures" if block.closure?
      config.user_data.method_bindings[config.user_data.method_sig(mod, klass, static?, signature)] = block
    end

    def bind_class(klass : String, mod : String = "main", &block : LibWren::ForeignMethodFn)
      raise "#{mod}.#{klass}: Bound class allocates can't have closures" if block.closure?
      config.user_data.class_bindings[config.user_data.class_sig(mod, klass)] = block
    end

    def bind(klass)
      klass.bind(self)
    end

    def call(klass : String, signature : String, args = [] of Value, mod = "main") : Value
      call_handle = get_call_handle(signature)
      klass_handle = get_klass_handle(mod, klass)

      LibWren.ensure_slots(_vm, args.size + 1)
      LibWren.set_slot_handle(_vm, 0, klass_handle)

      set_slots(args, start: 1)

      result = LibWren.call(_vm, call_handle)

      if result != LibWren::InterpretResult::RESULT_SUCCESS
        raise "Execution of #{mod}.#{klass}.true.#{signature} failed! #{result}"
      end

      get_slot(0)
    end

    def call(handle : Pointer(LibWren::Handle), signature : String, args = [] of Value, static = false, mod = "main") : Value
      call_handle = get_call_handle(signature)

      LibWren.ensure_slots(_vm, args.size + 1)
      LibWren.set_slot_handle(_vm, 0, handle)

      set_slots(args, start: 1)

      result = LibWren.call(_vm, call_handle)

      if result != LibWren::InterpretResult::RESULT_SUCCESS
        raise "Execution of #{mod}.handle.#{static}.#{signature} failed! #{result}"
      end

      get_slot(0)
    end

    def call(value : Value, signature : String, args = [] of Value, static = false, mod = "main") : Value
      call_handle = get_call_handle(signature)

      LibWren.ensure_slots(_vm, args.size + 1)
      set_slot(0, value)

      set_slots(args, start: 1)

      result = LibWren.call(_vm, call_handle)

      if result != LibWren::InterpretResult::RESULT_SUCCESS
        raise "Execution of #{mod}.handle.#{static}.#{signature} failed! #{result}"
      end

      get_slot(0)
    end

    def construct(klass : String, signature : String, args = [] of Value, mod = "main") : Pointer(LibWren::Handle)
      call_handle = get_call_handle(signature)
      klass_handle = get_klass_handle(mod, klass)

      LibWren.ensure_slots(_vm, args.size + 1)
      LibWren.set_slot_handle(_vm, 0, klass_handle)

      set_slots(args, start: 1)

      result = LibWren.call(_vm, call_handle)

      if result != LibWren::InterpretResult::RESULT_SUCCESS
        raise "Execution of #{mod}.#{klass}.true.#{signature} failed! #{result}"
      end

      LibWren.get_slot_handle(_vm, 0)
    end

    def set_slot(slot : Int32, value : Value)
      case value
      when Float64
        LibWren.set_slot_double(_vm, slot, value)
      when String
        LibWren.set_slot_string(_vm, slot, value.to_unsafe)
      when Bool
        LibWren.set_slot_bool(_vm, slot, value ? 1 : 0)
      when Nil
        LibWren.set_slot_null(_vm, slot)
      else
        raise "Cannot convert #{typeof(value)} to Wren"
      end
    end

    def set_slots(args : Array(Value), start : Int32 = 0)
      args.each_with_index do |arg, idx|
        set_slot(start + idx, arg)
      end
      GC.free(args.as(Void*))
    end

    def get_slot(slot : Int32) : Value
      case type = LibWren.get_slot_type(_vm, slot)
      when .bool?
        value = LibWren.get_slot_bool(_vm, slot)
        value == 1
      when .num?
        LibWren.get_slot_double(_vm, slot)
      when .null?
        nil
      when .string?
        String.new LibWren.get_slot_string(_vm, slot)
      else
        raise "Cannot convert #{type} in slot #{slot} from Wren"
      end
    end

    private def get_call_handle(signature : String)
      unless handle = config.user_data.call_handles[signature]?
        handle = LibWren.make_call_handle(_vm, signature.to_unsafe)
        config.user_data.call_handles[signature] = handle
      end
      handle
    end

    private def get_klass_handle(mod, klass)
      sig = config.user_data.class_sig(mod, klass)
      unless handle = config.user_data.slot_handles[sig]?
        LibWren.ensure_slots(_vm, 1)
        LibWren.get_variable(_vm, mod, klass, 0)
        handle = LibWren.get_slot_handle(_vm, 0)
        config.user_data.slot_handles[sig] = handle
      end

      handle
    end
  end
end
