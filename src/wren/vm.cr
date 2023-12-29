module Wren
  class VM
    getter _vm : Pointer(LibWren::Vm)
    getter config : Config

    def initialize(@config = Config.new)
      _config = @config._config
      @_vm = LibWren.new_vm(pointerof(_config))
    end

    def interpret(mod : String = "main", &) : LibWren::InterpretResult
      script = yield
      interpret(script, mod)
    end

    def interpret(script : String, mod : String = "main") : LibWren::InterpretResult
      LibWren.interpret(_vm, mod.to_unsafe, script.to_unsafe)
    end

    def bind_method(klass : String, static? : Bool, signature : String, mod : String = "main", &block : LibWren::ForeignMethodFn)
      config.user_data.method_bindings[config.user_data.method_sig(mod, klass, static?, signature)] = block
    end

    def bind_class(klass : String, mod : String = "main", &block : LibWren::ForeignMethodFn)
      config.user_data.class_bindings[config.user_data.class_sig(mod, klass)] = block
    end

    def call(klass, static, signature, *args, mod = "main")
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

    def set_slot(slot, value)
      case value
      when Float64
        LibWren.set_slot_double(_vm, slot, value)
      when String
        LibWren.set_slot_bytes(_vm, slot, value.to_unsafe, value.size)
      when Bool
        LibWren.set_slot_bool(_vm, slot, value ? 1 : 0)
      when Nil
        LibWren.set_slot_null(_vm, slot)
      else
        raise "Cannot convert #{typeof(arg)} to Wren"
      end
    end

    def get_slot(slot)
      case LibWren.get_slot_type(_vm, slot)
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
        raise "Cannot convert slot #{slot} from Wren"
      end
    end
  end
end
