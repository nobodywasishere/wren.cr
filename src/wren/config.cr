module Wren
  struct Config
    getter user_data : UserData = UserData.new

    # :nodoc:
    getter _config : LibWren::Configuration

    def initialize
      @_config = uninitialized LibWren::Configuration
      LibWren.init_configuration(pointerof(@_config))

      error do |vm, error_type, mod, line, msg|
        raise Exception.new(String.new(msg))
      end

      bind_foreign_method do |vm, mod, klass, static, signature|
        packed_user_data = LibWren.get_user_data(vm)
        user_data = Box(UserData).unbox(packed_user_data)

        sig = user_data.method_sig(mod, klass, static, signature)
        method = user_data.method_bindings[sig]?

        if method
          method
        else
          raise "No method binding for #{sig}"
        end
      end

      bind_foreign_class do |vm, mod, klass|
        packed_user_data = LibWren.get_user_data(vm)
        user_data = Box(UserData).unbox(packed_user_data)

        sig = user_data.class_sig(mod, klass)
        allocate = user_data.class_bindings[sig]?

        methods = LibWren::ForeignClassMethods.new

        if allocate
          methods.allocate = allocate
          methods.finalize = ->(data : Void*) {}
        else
          raise "No class binding for #{sig}"
        end

        methods
      end

      @_config.user_data = Box.box(@user_data)
    end

    macro bind_fn(name)
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
end
