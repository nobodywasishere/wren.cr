module Wren
  struct Config
    getter config : LibWren::Configuration

    def initialize
      @config = uninitialized LibWren::Configuration
      LibWren.init_configuration(pointerof(@config))
    end

    macro bind_fn(name)
      def {{ name.id }}=(proc : LibWren::{{ name.name.camelcase.id }}Fn)
        @config.{{ name.id }}_fn = proc
      end

      def {{ name.id }}(&block : LibWren::{{ name.name.camelcase.id }}Fn)
        @config.{{ name.id }}_fn = block
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
    getter vm : Pointer(LibWren::Vm)
    getter config : Config

    def initialize(@config)
      _config = @config.config
      @vm = LibWren.new_vm(pointerof(_config))
    end

    def finalize
      LibWren.free_vm(vm)
    end

    def interpret(mod : String = "main", &) : LibWren::InterpretResult
      script = yield
      interpret(script, mod)
    end

    def interpret(script : String, mod : String = "main") : LibWren::InterpretResult
      LibWren.interpret(vm, mod.to_unsafe, script.to_unsafe)
    end
  end
end
