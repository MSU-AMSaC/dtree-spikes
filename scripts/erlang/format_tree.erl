% format_tree.erl
% Bit-pack the hyperplane coefficients found in coeff_tree.erl
% and write them to a file.
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
