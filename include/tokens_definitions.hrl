-define(BRAINFUCK, sets:from_list([".", ",", "[", "]", "<", ">", "+", "-"])).
-define(BRAINFORK, sets:add_element("Y", ?BRAINFUCK)).
