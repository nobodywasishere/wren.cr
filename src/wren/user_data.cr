module Wren
  alias MethodBindings = Hash(String, LibWren::ForeignMethodFn)
  alias ClassBindings = Hash(String, LibWren::ForeignMethodFn)
  alias SlotHandles = Hash(String, Pointer(LibWren::Handle))

  class UserData
    property vm : WeakRef(Wren::VM)?
    property method_bindings = MethodBindings.new
    property class_bindings = ClassBindings.new
    property call_handles = SlotHandles.new
    property slot_handles = SlotHandles.new
    getter loaded_modules = Hash(String, String).new

    # Default module dirs are the current directory and the `./wren_modules` folder at the root of this repo.
    # Additional module dirs to search through can be added with:
    # ```
    # vm = Wren::VM.new
    # vm.config.user_data.module_dirs << "path/to/new/module/dir"
    # # or
    # vm.config.user_data.module_dirs << Path["path", "to", "new", "module", "dir"].to_s
    # ```
    getter module_dirs : Array(String) = [".", Path[__DIR__, "..", "..", "wren_modules"].to_s]

    def method_sig(mod, klass, static, signature) : String
      mod = String.new(mod) unless mod.is_a?(String)
      klass = String.new(klass) unless klass.is_a?(String)
      signature = String.new(signature) unless signature.is_a?(String)
      unless static.is_a?(Bool)
        static = static == 1
      end

      String.build do |s|
        s << mod << "."
        s << klass << "."
        s << static << "."
        s << signature
      end
    end

    def class_sig(mod, klass) : String
      mod = String.new(mod) unless mod.is_a?(String)
      klass = String.new(klass) unless klass.is_a?(String)

      String.build do |s|
        s << mod << "."
        s << klass
      end
    end
  end
end
