-module(format_tree).
-export([build_tree/0, write_tree/2, hexify/2]).

-include_lib("include/noderec.hrl").

hexify(Width, Bits) -> 
  case Bits of
    << Node:Width, Rest/binary >> ->
      Formatted = string:right(integer_to_list(Node, 16), 
                               Width div 4, $0), 
      Formatted ++ "\n" ++ hexify(Width, Rest);
    _Else ->
      ""
  end.

write_tree(Tree, Fname) ->
  Res   = bit_size(bittree:flatten(#node{}, 4)),
  Words = hexify(Res, bittree:flatten(Tree, 4)),
  file:write_file(Fname, Words).

build_tree() ->
  gb_trees:from_orddict(
    [ 
    {1, #node{ left_child  = 1
             , right_child = 0
             , coeffs      = [0.5, 1, -0.5]
             , bias        = 6
             }},
  
    {2, #node{ left_child  = 0
             , right_child = 0
             , coeffs      = [0, 0, 1]
             , bias        = -18
             }},
    {3, #node{ left_child  = 0
             , right_child = 0
             , coeffs      = [1, 0, 0]
             , bias        = -75
             }},
    {4, #node{ left_child  = 0
             , right_child = 0
             , coeffs      = [0, 0, 1]
             , bias        = 0
             }},
    {5, #node{ left_child  = 0
             , right_child = 0
             , coeffs      = [0, 0, 1]
             , bias        = 0
             }}
    ]).
  
