require "../spec_helper"

class MyClass
  include Wren::Class

  property thing : Bool = false

  foreign_def self.foo do |arg1, arg2|
    case {arg1, arg2}
    when {Float64, Float64}
      arg1 + arg2
    end
  end

  native_def self.init, construct: true

  foreign_def bar do |arg3|
    "goodbye moon! #{arg3}"
  end

  foreign_def bas do
  end

  native_def set_width, value do
    "return _width = value"
  end

  native_def get_width do
    "return _width"
  end

  native_def self.cheese, round do
    <<-WREN
    return "cheese wheel " + round
    WREN
  end
end

describe Wren::Class do
  it "defines a Wren class in Crystal code" do
    config = Wren::Config.new

    config.write do |_vm, txt|
      print String.new(txt)
    end

    vm = Wren::VM.new(config)

    MyClass.bind(vm)

    MyClass.foo(10, 20).should eq(30)

    vm.call("MyClass", "foo(_,_)", [10, 20]).should eq(30)

    MyClass.cheese("go round").should eq("cheese wheel go round")

    vm.call("MyClass", "cheese(_)", ["go round"]).should eq("cheese wheel go round")

    my_class = MyClass.init

    my_class.bar("kaboom").should eq("goodbye moon! kaboom")

    my_class.set_width(1)

    vm.call(my_class.instance_handle.not_nil!, "get_width()").should eq(1)

    result = vm.interpret <<-WREN
    var my_class = MyClass.init()
    my_class.get_width()
    WREN

    result.should eq(LibWren::InterpretResult::RESULT_SUCCESS)
  end
end
