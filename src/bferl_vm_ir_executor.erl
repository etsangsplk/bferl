-module(bferl_vm_ir_executor).

-include("../include/virtual_machine_definitions.hrl").

-export([ start_machine/1, step/1, run/1,
          register_tape/1, register_console/1 ]).

-type step_result() :: bferl_types:virtual_machine_state() | {finished, bferl_types:virtual_machine_state()}.

-spec build_jump_entry({pos_integer(), bferl_types:ir_opcode()}, map()) -> map().
build_jump_entry({I, {jze, N}}, Jumps) -> Jumps#{ I => N };
build_jump_entry({I, {jmp, N}}, Jumps) -> Jumps#{ I => N };
build_jump_entry(_, Jumps) -> Jumps.

-spec build_jump_table(bferl_types:ir_program()) -> map().
build_jump_table(Program) ->
    ProgramWithIndexes = lists:zip(lists:seq(1, length(Program)), Program),
    lists:foldl(fun build_jump_entry/2, #{}, ProgramWithIndexes).

-spec start_machine(bferl_types:ir_program()) -> bferl_types:virtual_machine_state().
start_machine(Program) when is_list(Program) ->
    Jumps = build_jump_table(Program),
    #register_based_virtual_machine{ir_code = Program, jmp_table = Jumps}.

-spec execute(bferl_types:ir_opcode(), bferl_types:virtual_machine_state()) -> bferl_types:virtual_machine_state().
execute({load, ir0, r0}, Machine) ->
    IR0 = Machine#register_based_virtual_machine.ir0,
    Memory = Machine#register_based_virtual_machine.memory,

    NewR0 = array:get(IR0, Memory),
    NewZF = case NewR0 of
        0 -> 1;
        _ -> 0
    end,

    Machine#register_based_virtual_machine{r0 = NewR0, zf = NewZF};

execute({store, r0, ir0}, Machine) ->
    IR0 = Machine#register_based_virtual_machine.ir0,
    R0 = Machine#register_based_virtual_machine.r0,

    Memory = Machine#register_based_virtual_machine.memory,
    NewMemory = array:set(IR0, R0, Memory),

    Machine#register_based_virtual_machine{memory = NewMemory};

execute({add, ir0, N}, Machine) when is_integer(N) ->
    NewIR0 = Machine#register_based_virtual_machine.ir0 + N,

    Machine#register_based_virtual_machine{ir0 = NewIR0};

execute({sub, ir0, N}, Machine) when is_integer(N) ->
    NewIR0 = Machine#register_based_virtual_machine.ir0 - N,

    Machine#register_based_virtual_machine{ir0 = NewIR0};

execute({add, r0, N}, Machine) when is_integer(N) ->
    NewR0 = Machine#register_based_virtual_machine.r0 + N,

    Machine#register_based_virtual_machine{r0 = NewR0};

execute({sub, r0, N}, Machine) when is_integer(N) ->
    NewR0 = Machine#register_based_virtual_machine.r0 - N,

    Machine#register_based_virtual_machine{r0 = NewR0};

execute({const, ir0, N}, Machine) when N > 0 ->
    Machine#register_based_virtual_machine{ir0 = N};

execute({const, r0, N}, Machine) when is_integer(N) ->
    NewZF = case N of
        0 -> 1;
        _ -> 0
    end,

    Machine#register_based_virtual_machine{r0 = N, zf = NewZF};

execute({jmp, N}, Machine) when N > 0 ->
    NewIP = N - 1,

    Machine#register_based_virtual_machine{ip = NewIP};

execute({jze, N}, Machine) when N > 0 ->
    NewIP = case Machine#register_based_virtual_machine.zf of
        1 -> N - 1;
        _ -> Machine#register_based_virtual_machine.ip
    end,

    Machine#register_based_virtual_machine{ip = NewIP};

execute({jnze, N}, Machine) when N > 0 ->
    NewIP = case Machine#register_based_virtual_machine.zf of
        0 -> N - 1;
        _ -> Machine#register_based_virtual_machine.ip
    end,

    Machine#register_based_virtual_machine{ip = NewIP};

execute({call, in}, Machine) ->
    Memory = Machine#register_based_virtual_machine.memory,
    IR0 = Machine#register_based_virtual_machine.ir0,

    {In, _, _} = Machine#register_based_virtual_machine.io,
    Read = In(),

    Machine#register_based_virtual_machine{memory = array:set(IR0, Read, Memory)};

execute({call, out}, Machine) ->
    IR0 = Machine#register_based_virtual_machine.ir0,
    Value = array:get(IR0, Machine#register_based_virtual_machine.memory),

    {_, Out, _} = Machine#register_based_virtual_machine.io,
    Out(Value),

    Machine;

execute({call, fork}, Machine) ->
    Machine.

-spec step(bferl_types:virtual_machine_state()) -> step_result().
step(Step) when Step#register_based_virtual_machine.ip > length(Step#register_based_virtual_machine.ir_code) ->
    {finished, Step};

step(Machine) ->
    IP = Machine#register_based_virtual_machine.ip,
    Instruction = lists:nth(IP, Machine#register_based_virtual_machine.ir_code),

    Modified = execute(Instruction, Machine),

    NewIP = Modified#register_based_virtual_machine.ip,
    IC = Modified#register_based_virtual_machine.ic,

    Modified#register_based_virtual_machine{ip = NewIP + 1, ic = IC + 1}.

-spec internal_run(step_result()) -> bferl_types:virtual_machine_state().
internal_run({finished, Result})  -> Result;
internal_run(Intermediate)        -> internal_run(step(Intermediate)).

-spec run(bferl_types:virtual_machine_state()) -> bferl_types:virtual_machine_state().
run(Machine) -> internal_run(step(Machine)).

-spec register_io(fun(), fun(), fun(), bferl_types:virtual_machine_state()) -> bferl_types:virtual_machine_state().
register_io(In, Out, NewLine, Machine) when is_function(In), is_function(Out), is_function(NewLine) ->
    Machine#register_based_virtual_machine{io = {In, Out, NewLine}}.

-spec register_tape(bferl_types:virtual_machine_state()) -> bferl_types:virtual_machine_state().
register_tape(Machine) ->
    register_io(fun bferl_io:get_character_from_tape/0,
                fun bferl_io:put_character_to_tape/1,
                fun bferl_io:new_line_on_tape/0,
                Machine).

-spec register_console(bferl_types:virtual_machine_state()) -> bferl_types:virtual_machine_state().
register_console(Machine) ->
    register_io(fun bferl_io:get_character_from_console/0,
                fun bferl_io:put_character_to_console/1,
                fun bferl_io:new_line_on_console/0,
                Machine).
