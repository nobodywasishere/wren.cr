module Wren
  record Method,
    name : String,
    args : String,
    foreign : Bool,
    klass : String,
    static : Bool,
    construct : Bool,
    sig : String,
    mod : String = "main",
    block : Proc(Pointer(LibWren::Vm), Nil)? = nil,
    native_code : String? = nil

  #
  # Mixin that when included in a class, adds macros for defining foreign and native
  # Wren methods attached to the class
  #
  # ```
  # class MyClass
  #   include Wren::Class
  #
  #   foreign_def self.method1 do
  #     "response1"
  #   end
  #
  #   native_def self.method2 do
  #     <<-WREN
  #       "response2"
  #     WREN
  #   end
  # end
  # ```
  #
  module Class
    WREN_METHODS = [] of Wren::Method

    property instance_handle : Pointer(LibWren::Handle)?

    private macro build_sig(name, &block)
      String.build do |s|
        s << {{ name.id.gsub(/^self./, "").stringify }}
        s << "("
        {% for i in (0...block.args.size - 1) %}
          s << "_,"
        {% end %}
        {% if block.args.size > 0 %}
          s << "_"
        {% end %}
        s << ")"
      end
    end

    private macro build_method(method)
      String.build do |s|
        if method.foreign
          s << "foreign "
        end
        if method.static
          if method.construct
            s << "construct "
          else
            s << "static "
          end
          s << method.name.gsub(/^self\./, "")
        else
          s << method.name
        end
        s << "("
        s << method.args
        s << ")"
        if !method.foreign
          s << " {\n  "
          s << method.native_code
          s << "\n  }"
        end
      end
    end

    # Define a method in native Wren code, callable from either Wren or Crystal.
    # Cannot be modified at runtime.
    #
    # ```
    # class MyClass
    #   include Wren::Class
    #
    #   native_def self.my_method, arg1, <<-WREN
    #     return "foo " + arg1
    #   WREN
    # end
    #
    # MyClass.my_method("bar") # => "foo bar"
    # ```
    macro native_def(name, *args, construct = false, &code)
      def {{ name }}({{ args.splat }})
        sig = build_sig({{ name }}) { {% if args.size > 0 %}|{{ args.splat }}|{% end %} }
        {% if name.id.starts_with?("self.") %}
          {% if construct %}
            ihandle = @@vm.not_nil!.construct({{ @type.stringify }}, sig, {{ args.splat }})
            item = self.new
            item.instance_handle = ihandle
            item
          {% else %}
            @@vm.not_nil!.call({{ @type.stringify }}, sig, [{{ args.splat }}] of Wren::Value)
          {% end %}
        {% else %}
          @@vm.not_nil!.call(@instance_handle.not_nil!, sig, [{{ args.splat }}] of Wren::Value)
        {% end %}
      end

      WREN_METHODS << Wren::Method.new(
        name: {{ name.stringify }},
        args: {{ args.splat.stringify }},
        foreign: false,
        klass: {{ @type.stringify }},
        static: {{ name.id.starts_with?("self.") }},
        construct: {{ construct }},
        sig: build_sig({{ name }}) { {% if args.size > 0 %}|{{ args.splat }}|{% end %} },
        {% if code %}
        native_code: ->{ {{ code.body }} }.call
        {% else %}
        native_code: ""
        {% end %}
      )
    end

    # Define a method in foreign Crystal code, callable from either Wren or Crystal.
    # Does not support foreign constructs
    #
    # ```
    # class MyClass
    #   include Wren::Class
    #
    #   foreign_def self.my_method do |arg1|
    #     case arg1
    #     when String
    #       "foo " + arg1
    #     end
    #   end
    # end
    #
    # MyClass.my_method("bar") # => "foo bar"
    # ```
    macro foreign_def(name, &block)
      def {{ name }}({{ block.args.splat }})
        sig = build_sig({{ name }}) { {% if block.args.size > 0 %}|{{ block.args.splat }}|{% end %} }
        {% if name.id.starts_with?("self.") %}
          @@vm.not_nil!.call({{ @type.stringify }}, sig, [{{ block.args.splat }}] of Wren::Value)
        {% else %}
          @@vm.not_nil!.call(@instance_handle.not_nil!, sig, [{{ block.args.splat }}] of Wren::Value)
        {% end %}
      end

      WREN_METHODS << Wren::Method.new(
        name: {{ name.stringify }},
        args: {{ block.args.splat.stringify }},
        foreign: true,
        klass: {{ @type.stringify }},
        static: {{ name.id.starts_with?("self.") }},
        construct: false,
        sig: build_sig({{ name }}) { {% if block.args.size > 0 %}|{{ block.args.splat }}|{% end %} },
        block: ->(_vm : Pointer(LibWren::Vm)) {
          packed_user_data = LibWren.get_user_data(_vm)
          user_data = Box(Wren::UserData).unbox(packed_user_data)

          %vm = user_data.vm.not_nil!

          {% for idx in (0...block.args.size) %}
          {{ block.args[idx] }} = %vm.get_slot({{ idx }} + 1)
          {% end %}

          result = begin
            {{ block.body }}
          end

          %vm.set_slot(0, result)
        }
      )
    end

    # Binds this instance to a specific VM
    def bind(vm : Wren::VM)
      self.class.bind(vm)
    end

    macro included
      class_property vm : Wren::VM?

      # Converts the current class to the equivalent Wren class code
      def self.to_wren : String
        String.build do |s|
          s << "class "
          s << {{ @type }}
          s << "{\n"
          WREN_METHODS.each do |method|
            s << "  "
            s << build_method(method)
            s << "\n"
          end
          s << "}"
        end
      end

      # Binds this class to a specific VM,
      # classes themselves can only be bound to one VM at a time
      def self.bind(vm : Wren::VM)
        @@vm = vm
        WREN_METHODS.each do |method|
          if method.foreign
            vm.bind_method(method.klass, method.static, method.sig, &method.block.not_nil!)
          end
        end
        vm.interpret(self.to_wren)
      end

      def initialize
        if WREN_METHODS.all? { |method| !method.construct }
          raise "Wren::Class's cannot be instantiated from Crystal without a construct def"
        end
      end

      def finalize
        # Potential bug here if finalizer called after @@vm has changed
        if instance_handle = @instance_handle
          LibWren.release_handle(@@vm.not_nil!._vm, instance_handle)
        end
      end
    end
  end
end
