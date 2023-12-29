module Wren
  struct Config
    getter _config : LibWren::Configuration

    def initialize
      @_config = uninitialized LibWren::Configuration
      LibWren.init_configuration(pointerof(@_config))
    end

    macro bind_fn(name)
      def {{ name.id }}=(proc : LibWren::{{ name.name.camelcase.id }}Fn)
        @_config.{{ name.id }}_fn = proc
      end

      def {{ name.id }}(&block : LibWren::{{ name.name.camelcase.id }}Fn)
        @_config.{{ name.id }}_fn = block
      end
    end

    bind_fn(reallocate)

    bind_fn(resolve_module)

    bind_fn(load_module)

    bind_fn(bind_foreign_method)

    bind_fn(bind_foreign_class)

    bind_fn(write)

    bind_fn(error)
  end

  class VM
    getter _vm : Pointer(LibWren::Vm)
    getter config : Config

    def initialize(@config)
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
  end
end
