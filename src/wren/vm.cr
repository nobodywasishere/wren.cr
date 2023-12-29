module Wren
  class VM
    getter _vm : Pointer(LibWren::Vm)
    getter config : Config

    def initialize(@config = Config.new)
      _config = @config._config
      @_vm = LibWren.new_vm(pointerof(_config))
    end

    def finalize
      LibWren.free_vm(_vm)
    end

    def interpret(mod : String = "main", &) : LibWren::InterpretResult
      script = yield
      interpret(script, mod)
    end

    def interpret(script : String, mod : String = "main") : LibWren::InterpretResult
      LibWren.interpret(_vm, mod.to_unsafe, script.to_unsafe)
    end

    def bind_method(mod : String, klass : String, static? : Bool, signature : String, &block : LibWren::ForeignMethodFn)
      config.user_data.method_bindings[config.user_data.method_sig(mod, klass, static?, signature)] = block
    end

    def bind_class(mod : String, klass : String, &block : LibWren::ForeignMethodFn)
      config.user_data.class_bindings[config.user_data.class_sig(mod, klass)] = block
    end
  end
end
