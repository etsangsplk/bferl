-module(tokenizer_properties_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([ all/0 ]).
-export([ tokenizer_should_exclude_superfluous_tokens/1,
          tokenizer_should_use_whitelist_as_a_base_for_excluding_tokens/1 ]).


all() ->
    [ tokenizer_should_exclude_superfluous_tokens,
      tokenizer_should_use_whitelist_as_a_base_for_excluding_tokens ].

tokenizer_should_exclude_superfluous_tokens(_Context) ->
    ?assertEqual(true,
                 proper:quickcheck(tokenizer_model:prop_tokenizer_should_exclude_superfluous_tokens(),
                                   [ {to_file, user}, {numtests, 1000} ])).

tokenizer_should_use_whitelist_as_a_base_for_excluding_tokens(_Context) ->
    ?assertEqual(true,
                 proper:quickcheck(tokenizer_model:prop_tokenizer_should_whitelist_tokens_based_on_input(),
                                   [ {to_file, user}, {numtests, 1000} ])).
