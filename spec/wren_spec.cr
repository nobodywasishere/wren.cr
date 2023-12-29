require "./spec_helper"

describe Wren do
  it "interprets code and handles output" do
    config = Wren::Config.new

    config.write do |vm, text|
      [
        "I am running in a VM!",
        "\n",
      ].should contain(String.new(text))
    end

    vm = Wren::VM.new(config)

    result = vm.interpret do
      <<-WREN
      System.print("I am running in a VM!")
      WREN
    end

    result.should eq(LibWren::InterpretResult::RESULT_SUCCESS)
  end

  it "can call methods and get return values" do
    config = Wren::Config.new

    config.write do |vm, text|
      [
        "hello world",
        "\n",
      ].should contain(String.new(text))
    end

    vm = Wren::VM.new(config)

    script = <<-WREN
    class GameEngine {
      static update(elapsedTime) {
        System.print("hello world")
        // ...
        return "cheese"
      }
    }
    WREN

    vm.interpret(script)

    vm.call("GameEngine", true, "update(_)").should eq("cheese")
  end

  it "can bind a foreign method to a Crystal proc" do
    config = Wren::Config.new

    config.write do |vm, text|
      [
        "4",
        "\n",
      ].should contain(String.new(text))
    end

    vm = Wren::VM.new(config)

    vm.bind_method("Math", true, "add(_,_)") do |vm|
      a = LibWren.get_slot_double(vm, 1)
      b = LibWren.get_slot_double(vm, 2)
      LibWren.set_slot_double(vm, 0, a + b)
    end

    vm.interpret do
      <<-WREN
      class Math {
        foreign static add(a, b)

        static twoplustwo() {
          var c = add(2, 2)
          System.print(c)
          return c
        }
      }
      WREN
    end

    result = vm.call("Math", true, "twoplustwo()")

    result.should eq(4.0_f64)
  end

  it "can pass arguments to Wren methods" do
    vm = Wren::VM.new

    vm.interpret <<-WREN
    class Math {
      static add(a, b) {
        return a + b
      }
    }
    WREN

    vm.call("Math", true, "add(_,_)", 1_f64, 2_f64).should eq(3_f64)
  end
end
