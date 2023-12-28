@[Link(ldflags: "#{__DIR__}/../ext/wren.a -lm")]
lib LibWren
  # Creates a handle that can be used to invoke a method with [signature] on
  # using a receiver and arguments that are set up on the stack.
  #
  # This handle can be used repeatedly to directly invoke that method from C
  # code using [wrenCall].
  #
  # When you are done with this handle, it must be released using
  # [wrenReleaseHandle].
  alias Handle = Void

  # A single virtual machine for executing Wren code.
  #
  # Wren has no global state, so all state stored by a running interpreter lives
  # here.
  alias Vm = Void

  # Sets the current fiber to be aborted, and uses the value in [slot] as the
  # runtime error object.
  fun abort_fiber = wrenAbortFiber(vm : Vm*, slot : LibC::Int) : Void

  # Creates a handle that can be used to invoke a method with [signature] on
  # using a receiver and arguments that are set up on the stack.
  #
  # This handle can be used repeatedly to directly invoke that method from C
  # code using [wrenCall].
  #
  # When you are done with this handle, it must be released using
  # [wrenReleaseHandle].
  fun call = wrenCall(vm : Vm*, method : Void*) : InterpretResult

  # Immediately run the garbage collector to free unused memory.
  fun collect_garbage = wrenCollectGarbage(vm : Vm*)

  # Ensures that the foreign method stack has at least [numSlots] available for
  # use, growing the stack if needed.
  #
  # Does not shrink the stack if it has more than enough slots.
  #
  # It is an error to call this from a finalizer.
  fun ensure_slots = wrenEnsureSlots(vm : Vm*, num_slots : LibC::Int) : Void

  # Disposes of all resources is use by [vm], which was previously created by a
  # call to [wrenNewVM].
  fun free_vm = wrenFreeVM(vm : Vm*)

  # Returns the number of elements in the list stored in [slot].
  fun get_list_count = wrenGetListCount(vm : Vm*, slot : LibC::Int) : LibC::Int

  # Reads element [index] from the list in [listSlot] and stores it in
  # [elementSlot].
  fun get_list_element = wrenGetListElement(vm : Vm*, list_slot : LibC::Int, index : LibC::Int, element_slot : LibC::Int)

  # Returns true if the key in [keySlot] is found in the map placed in [mapSlot].
  fun get_map_contains_key = wrenGetMapContainsKey(vm : Vm*, map_slot : LibC::Int, key_slot : LibC::Int) : LibC::Int

  # Returns the number of entries in the map stored in [slot].
  fun get_map_count = wrenGetMapCount(vm : Vm*, slot : LibC::Int) : LibC::Int

  # Retrieves a value with the key in [keySlot] from the map in [mapSlot] and
  # stores it in [valueSlot].
  fun get_map_value = wrenGetMapValue(vm : Vm*, map_slot : LibC::Int, key_slot : LibC::Int, value_slot : LibC::Int)

  # Reads a boolean value from [slot].
  #
  # It is an error to call this if the slot does not contain a boolean value.
  fun get_slot_bool = wrenGetSlotBool(vm : Vm*, slot : LibC::Int) : LibC::Int

  # Reads a byte array from [slot].
  #
  # The memory for the returned string is owned by Wren. You can inspect it
  # while in your foreign method, but cannot keep a pointer to it after the
  # function returns, since the garbage collector may reclaim it.
  #
  # Returns a pointer to the first byte of the array and fill [length] with the
  # number of bytes in the array.
  #
  # It is an error to call this if the slot does not contain a string.
  fun get_slot_bytes = wrenGetSlotBytes(vm : Vm*, slot : LibC::Int, length : LibC::Int*) : LibC::Char*

  # Returns the number of slots available to the current foreign method.
  fun get_slot_count = wrenGetSlotCount(vm : Vm*) : LibC::Int

  # Reads a number from [slot].
  #
  # It is an error to call this if the slot does not contain a number.
  fun get_slot_double = wrenGetSlotDouble(vm : Vm*, slot : LibC::Int) : LibC::Double

  # Reads a foreign object from [slot] and returns a pointer to the foreign data
  # stored with it.
  #
  # It is an error to call this if the slot does not contain an instance of a
  # foreign class.
  fun get_slot_foreign = wrenGetSlotForeign(vm : Vm*, slot : LibC::Int) : Void*

  # Creates a handle for the value stored in [slot].
  #
  # This will prevent the object that is referred to from being garbage collected
  # until the handle is released by calling [wrenReleaseHandle()].
  fun get_slot_handle = wrenGetSlotHandle(vm : Vm*, slot : LibC::Int) : Void*

  # Reads a string from [slot].
  #
  # The memory for the returned string is owned by Wren. You can inspect it
  # while in your foreign method, but cannot keep a pointer to it after the
  # function returns, since the garbage collector may reclaim it.
  #
  # It is an error to call this if the slot does not contain a string.
  fun get_slot_string = wrenGetSlotString(vm : Vm*, slot : LibC::Int) : LibC::Char*

  # Gets the type of the object in [slot].
  fun get_slot_type = wrenGetSlotType(vm : Vm*, slot : LibC::Int) : Type

  # Returns the user data associated with the WrenVM.
  fun get_user_data = wrenGetUserData(vm : Vm*) : Void*

  # Looks up the top level variable with [name] in resolved [module] and stores
  # it in [slot].
  fun get_variable = wrenGetVariable(vm : Vm*, module : LibC::Char*, name : LibC::Char*, slot : LibC::Int)

  # Get the current wren version number.
  #
  # Can be used to range checks over versions.
  fun get_version_number = wrenGetVersionNumber : LibC::Int

  # Looks up the top level variable with [name] in resolved [module],
  # returns false if not found. The module must be imported at the time,
  # use wrenHasModule to ensure that before calling.
  fun has_module = wrenHasModule(vm : Vm*, module : LibC::Char*) : LibC::Int

  # Looks up the top level variable with [name] in resolved [module],
  # returns false if not found. The module must be imported at the time,
  # use wrenHasModule to ensure that before calling.
  fun has_variable = wrenHasVariable(vm : Vm*, module : LibC::Char*, name : LibC::Char*) : LibC::Int

  # Initializes [configuration] with all of its default values.
  #
  # Call this before setting the particular fields you care about.
  fun init_configuration = wrenInitConfiguration(configuration : Void*)

  # Takes the value stored at [elementSlot] and inserts it into the list stored
  # at [listSlot] at [index].
  #
  # As in Wren, negative indexes can be used to insert from the end. To append
  # an element, use `-1` for the index.
  fun insert_in_list = wrenInsertInList(vm : Vm*, list_slot : LibC::Int, index : LibC::Int, element_slot : LibC::Int)

  # Runs [source], a string of Wren source code in a new fiber in [vm] in the
  # context of resolved [module].
  fun interpret = wrenInterpret(vm : Vm*, module : LibC::Char*, source : LibC::Char*) : InterpretResult

  # Creates a handle that can be used to invoke a method with [signature] on
  # using a receiver and arguments that are set up on the stack.
  #
  # This handle can be used repeatedly to directly invoke that method from C
  # code using [wrenCall].
  #
  # When you are done with this handle, it must be released using
  # [wrenReleaseHandle].
  fun make_call_handle = wrenMakeCallHandle(vm : Vm*, signature : LibC::Char*) : Void*

  # Creates a new Wren virtual machine using the given [configuration]. Wren
  # will copy the configuration data, so the argument passed to this can be
  # freed after calling this. If [configuration] is `NULL`, uses a default
  # configuration.
  fun new_vm = wrenNewVM(configuration : Void*) : Void*

  # Releases the reference stored in [handle]. After calling this, [handle] can
  # no longer be used.
  fun release_handle = wrenReleaseHandle(vm : Vm*, handle : Void*) : Void

  # Removes a value from the map in [mapSlot], with the key from [keySlot],
  # and place it in [removedValueSlot]. If not found, [removedValueSlot] is
  # set to null, the same behaviour as the Wren Map API.
  fun remove_map_value = wrenRemoveMapValue(vm : Vm*, map_slot : LibC::Int, key_slot : LibC::Int, removed_value_slot : LibC::Int)

  # Sets the value stored at [index] in the list at [listSlot],
  # to the value from [elementSlot].
  fun set_list_element = wrenSetListElement(vm : Vm*, list_slot : LibC::Int, index : LibC::Int, element_slot : LibC::Int)

  # Takes the value stored at [valueSlot] and inserts it into the map stored
  # at [mapSlot] with key [keySlot].
  fun set_map_value = wrenSetMapValue(vm : Vm*, map_slot : LibC::Int, key_slot : LibC::Int, value_slot : LibC::Int)

  # Stores the boolean [value] in [slot].
  fun set_slot_bool = wrenSetSlotBool(vm : Vm*, slot : LibC::Int, value : LibC::Int)

  # Stores the array [length] of [bytes] in [slot].
  #
  # The bytes are copied to a new string within Wren's heap, so you can free
  # memory used by them after this is called.
  fun set_slot_bytes = wrenSetSlotBytes(vm : Vm*, slot : LibC::Int, bytes : LibC::Char*, length : LibC::SizeT)

  # Stores the numeric [value] in [slot].
  fun set_slot_double = wrenSetSlotDouble(vm : Vm*, slot : LibC::Int, value : LibC::Double)

  # Stores the value captured in [handle] in [slot].
  #
  # This does not release the handle for the value.
  fun set_slot_handle = wrenSetSlotHandle(vm : Vm*, slot : LibC::Int, handle : Void*)

  # Creates a new instance of the foreign class stored in [classSlot] with [size]
  # bytes of raw storage and places the resulting object in [slot].
  #
  # This does not invoke the foreign class's constructor on the new instance. If
  # you need that to happen, call the constructor from Wren, which will then
  # call the allocator foreign method. In there, call this to create the object
  # and then the constructor will be invoked when the allocator returns.
  #
  # Returns a pointer to the foreign object's data.
  fun set_slot_new_foreign = wrenSetSlotNewForeign(vm : Vm*, slot : LibC::Int, class_slot : LibC::Int, size : LibC::SizeT) : Void*

  # Stores a new empty list in [slot].
  fun set_slot_new_list = wrenSetSlotNewList(vm : Vm*, slot : LibC::Int)

  # Stores a new empty map in [slot].
  fun set_slot_new_map = wrenSetSlotNewMap(vm : Vm*, slot : LibC::Int)

  # Stores null in [slot].
  fun set_slot_null = wrenSetSlotNull(vm : Vm*, slot : LibC::Int)

  # Stores the string [text] in [slot].
  #
  # The [text] is copied to a new string within Wren's heap, so you can free
  # memory used by it after this is called. The length is calculated using
  # [strlen()]. If the string may contain any null bytes in the middle, then you
  # should use [wrenSetSlotBytes()] instead.
  fun set_slot_string = wrenSetSlotString(vm : Vm*, slot : LibC::Int, text : LibC::Char*)

  # Sets user data associated with the WrenVM.
  fun set_user_data = wrenSetUserData(vm : Vm*, user_data : Void*)

  struct Configuration
    reallocate_fn : ReallocateFn
    resolve_module_fn : ResolveModuleFn
    load_module_fn : LoadModuleFn
    bind_foreign_method_fn : BindForeignMethodFn
    bind_foreign_class_fn : BindForeignClassFn
    write_fn : WriteFn
    error_fn : ErrorFn
    initial_heap_size : LibC::SizeT
    min_heap_size : LibC::SizeT
    heap_growth_percent : LibC::Int
    user_data : Void*
  end

  struct ForeignClassMethods
    allocate : ForeignMethodFn
    finalize : FinalizerFn
  end

  struct LoadModuleResult
    source : LibC::Char*
    on_complete : LoadModuleCompleteFn
    user_data : Void*
  end

  enum InterpretResult
    RESULT_SUCCESS
    RESULT_COMPILE_ERROR
    RESULT_RUNTIME_ERROR
  end

  # The type of an object stored in a slot.
  #
  # This is not necessarily the object's *class*, but instead its low level
  # representation type.
  enum Type
    WREN_TYPE_BOOL
    WREN_TYPE_NUM
    WREN_TYPE_FOREIGN
    WREN_TYPE_LIST
    WREN_TYPE_MAP
    WREN_TYPE_NULL
    WREN_TYPE_STRING

    # The object is of a type that isn't accessible by the C API.
    WREN_TYPE_UNKNOWN
  end

  enum ErrorType
    ERROR_COMPILE
    ERROR_RUNTIME
    ERROR_STACK_TRACE
  end

  # void* reallocate_fn(void* memory, size_t newSize, void* userData)
  alias ReallocateFn = Proc(Void*, LibC::SizeT, Void*, Void*)

  # const char* resolve_module_fn(WrenVM* vm, const char* importer, const char* name)
  alias ResolveModuleFn = Proc(Vm*, LibC::Char*, LibC::Char*, LibC::Char*)

  # WrenLoadModuleResult load_module_fn(WrenVM* vm, const char* name)
  alias LoadModuleFn = Proc(Vm*, LibC::Char*, LoadModuleResult)

  alias ForeignMethodFn = Proc(Vm*, Void)

  alias BindForeignMethodFn = Proc(Vm*, LibC::Char*, LibC::Char*, LibC::Int, LibC::Char*, ForeignMethodFn)

  alias BindForeignClassFn = Proc(Vm*, LibC::Char*, LibC::Char*, ForeignClassMethods)

  alias WriteFn = Proc(Vm*, LibC::Char*, Void)

  alias ErrorFn = Proc(Vm*, ErrorType, LibC::Char*, LibC::Int, LibC::Char*, Void)

  alias FinalizerFn = Proc(Void*, Void)

  alias LoadModuleCompleteFn = Proc(Vm*, LibC::Char*, LoadModuleResult, Void)
end
