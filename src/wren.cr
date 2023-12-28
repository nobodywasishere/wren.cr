require "./lib_wren/lib_wren.cr"

module Wren
  alias VM = Pointer(LibWren::Vm)
end

write_fn = ->(_vm : Wren::VM, text : UInt8*) {
  print String.new text
}

error_fn = ->(_vm : Wren::VM, error_type : LibWren::ErrorType, mod : UInt8*, line : LibC::Int, msg : UInt8*) {
  case error_type
  in .error_compile?
    puts "[#{String.new(mod)} line #{line}] [Error] #{String.new(msg)}"
  in .error_runtime?
    puts "[#{String.new(mod)} line #{line}] in #{String.new(msg)}"
  in .error_stack_trace?
    puts "[Runtime Error] #{String.new(msg)}"
  end
}

config = uninitialized LibWren::Configuration
LibWren.init_configuration(pointerof(config))
config.write_fn = write_fn
config.error_fn = error_fn
vm = LibWren.new_vm(pointerof(config))

mod = "main"
script = <<-WREN
System.print("I am running in a VM!")
WREN

result = LibWren.interpret(vm, mod.to_unsafe, script.to_unsafe)

case result
in .result_compile_error?
  puts "Compile error!"
in .result_runtime_error?
  puts "Runtime error!"
in .result_success?
  puts "Success!"
end

LibWren.free_vm(vm)
