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

    config.error do |vm, error_type, mod, line, msg|
      raise Exception.new(String.new(msg))
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

    config.error do |vm, error, mod, line, msg|
      raise Exception.new(String.new(msg))
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

    update_handle = LibWren.make_call_handle(vm._vm, "update(_)")

    LibWren.ensure_slots(vm._vm, 1)
    LibWren.get_variable(vm._vm, "main", "GameEngine", 0)
    game_engine_handle = LibWren.get_slot_handle(vm._vm, 0)

    LibWren.set_slot_handle(vm._vm, 0, game_engine_handle)
    LibWren.set_slot_double(vm._vm, 1, 0.1_f64)

    result = LibWren.call(vm._vm, update_handle)

    result.should eq(LibWren::InterpretResult::RESULT_SUCCESS)

    String.new(LibWren.get_slot_string(vm._vm, 0)).should eq("cheese")

    LibWren.release_handle(vm._vm, update_handle)
    LibWren.release_handle(vm._vm, game_engine_handle)
  end

  it "can bind a foreign method to a Crystal proc" do
    config = Wren::Config.new

    config.write do |vm, text|
      [
        "4",
        "\n",
      ].should contain(String.new(text))
    end

    config.error do |vm, error, mod, line, msg|
      raise Exception.new(String.new(msg))
    end

    vm = Wren::VM.new(config)

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

    vm.bind_method("main", "Math", true, "add(_,_)") do |vm|
      a = LibWren.get_slot_double(vm, 1)
      b = LibWren.get_slot_double(vm, 2)
      LibWren.set_slot_double(vm, 0, a + b)
    end

    twoplus_handle = LibWren.make_call_handle(vm._vm, "twoplustwo()")

    LibWren.ensure_slots(vm._vm, 1)
    LibWren.get_variable(vm._vm, "main", "Math", 0)
    math_handle = LibWren.get_slot_handle(vm._vm, 0)

    LibWren.set_slot_handle(vm._vm, 0, math_handle)

    result = LibWren.call(vm._vm, twoplus_handle)

    result.should eq(LibWren::InterpretResult::RESULT_SUCCESS)

    LibWren.get_slot_double(vm._vm, 0).should eq(4.0_f64)

    LibWren.release_handle(vm._vm, twoplus_handle)
    LibWren.release_handle(vm._vm, math_handle)
  end
end
