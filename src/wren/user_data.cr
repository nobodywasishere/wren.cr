module Wren
  alias MethodBindings = Hash(String, LibWren::ForeignMethodFn)
  alias ClassBindings = Hash(String, LibWren::ForeignMethodFn)

  struct UserData
    property method_bindings = MethodBindings.new
    property class_bindings = ClassBindings.new

    def method_sig(mod, klass, static, signature) : String
      mod = String.new(mod) unless mod.is_a?(String)
      klass = String.new(klass) unless klass.is_a?(String)
      signature = String.new(signature) unless signature.is_a?(String)
      if static.is_a?(Bool)
        static = static.to_s
      else
        static = static == 1 ? "true" : false
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
