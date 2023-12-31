module Wren
  class VM
    # :nodoc:
    getter _vm : Pointer(LibWren::Vm)

    getter config : Config

    def initialize(@config = Config.new)
      _config = @config._config
      @_vm = LibWren.new_vm(pointerof(_config))

      config.user_data.vm = self
    end

    def finalize
      LibWren.free_vm(_vm)

      config.user_data.call_handles.each do |_, handle|
        LibWren.release_handle(_vm, handle)
      end

      config.user_data.slot_handles.each do |_, handle|
        LibWren.release_handle(_vm, handle)
      end
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

    def call(klass : String, static : Bool, signature : String, *args, mod = "main")
      unless call_handle = config.user_data.call_handles[signature]?
        call_handle = LibWren.make_call_handle(_vm, signature.to_unsafe)
        config.user_data.call_handles[signature] = call_handle
      end

      unless klass_handle = config.user_data.slot_handles[config.user_data.class_sig(mod, klass)]?
        LibWren.ensure_slots(_vm, 1)
        LibWren.get_variable(_vm, mod, klass, 0)
        klass_handle = LibWren.get_slot_handle(_vm, 0)
        config.user_data.slot_handles[config.user_data.class_sig(mod, klass)] = klass_handle
      end

      LibWren.ensure_slots(_vm, args.size + 1)
      LibWren.set_slot_handle(_vm, 0, klass_handle)

      args.each_with_index do |arg, idx|
        set_slot(idx + 1, arg)
      end

      result = LibWren.call(_vm, call_handle)

      if result != LibWren::InterpretResult::RESULT_SUCCESS
        raise "Execution of #{mod}.#{klass}.#{static}.#{signature} failed! #{result}"
      end

      get_slot(0)
    end

    def set_slot(slot : Int32, value)
      case value
      when Float64
        LibWren.set_slot_double(_vm, slot, value)
      when Int
        LibWren.set_slot_double(_vm, slot, value.to_f64)
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

    def get_slot(slot : Int32)
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
  end
end
