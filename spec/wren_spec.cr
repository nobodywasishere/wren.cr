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

    vm = Wren::VM.new(config.config)

    result = vm.interpret do
      <<-WREN
      System.print("I am running in a VM!")
      WREN
    end

    result.should eq(LibWren::InterpretResult::RESULT_SUCCESS)
  end
end
