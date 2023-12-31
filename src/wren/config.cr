module Wren
  class Config
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

      load_module do |vm, mod|
        packed_user_data = LibWren.get_user_data(vm)
        user_data = Box(UserData).unbox(packed_user_data)

        mod = String.new(mod)

        result = LibWren::LoadModuleResult.new
        result.source = Pointer(UInt8).null
        result.on_complete = ->(_vm : Pointer(LibWren::Vm), _mod : Pointer(UInt8), result : LibWren::LoadModuleResult) {
          _packed_user_data = LibWren.get_user_data(_vm)
          _user_data = Box(UserData).unbox(_packed_user_data)

          _user_data.loaded_modules.delete String.new(_mod)
        }
        result.user_data = Pointer(Void).null

        if (vm = user_data.vm)
          vm.module_dirs.each do |dir|
            if File.exists?(mod_path = Path[dir, mod]) || File.exists?(mod_path = Path[dir, mod + ".wren"])
              source = File.read(mod_path)
              result.source = source.to_unsafe
              user_data.loaded_modules[mod] = source
              break
            end
          end
        end

        result
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

    # Overriding this method will break the default module implementation
    # utilizing `Wren::VM.module_dirs`
    bind_fn(load_module)

    # Overriding this method will break `Wren::VM#bind_method`
    bind_fn(bind_foreign_method)

    # Overriding this method will break `Wren::VM#bind_class`
    bind_fn(bind_foreign_class)

    bind_fn(write)

    bind_fn(error)
  end
end
