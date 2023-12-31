# wren.cr

Crystal bindings to the [Wren](https://wren.io) interpreter.

Includes additional libraries / utilities out of the box:
- [wren-json](https://github.com/brandly/wren-json)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     wren:
       github: nobodywasishere/wren.cr
   ```

2. Run `shards install`
3. Run `./src/ext/generate.sh`

## Usage

```crystal
require "wren"

vm = Wren::VM.new

vm.bind_method("MyKlass", true, "method(_,_)") do |vm|
  a = LibWren.get_slot_double(vm, 1)
  b = LibWren.get_slot_double(vm, 2)
  LibWren.set_slot_double(vm, 0, a + b)
end

vm.interpret <<-WREN
class MyKlass {
  foreign static method(a, b)
}
WREN

puts vm.call("MyKlass", "method(_,_)", [1, 2]) # => 3.0_f64
```

## Contributing

1. Fork it (<https://github.com/nobodywasishere/wren.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Margret Riegert](https://github.com/nobodywasishere) - creator and maintainer
