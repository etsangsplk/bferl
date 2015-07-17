-define(MEMORY_SIZE, 30000).
-define(EMPTY_MEMORY, array:new([ {size, ?MEMORY_SIZE}, {fixed, true}, {default, 0} ])).

-record(interpreter, { io = undefined, stack = [],
                       instructions = undefined, instructions_pointer = 0,
                       memory_pointer = 0, memory = ?EMPTY_MEMORY }).
