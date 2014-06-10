-module(bittree).
-export([flatten/2]).

-include_lib("include/noderec.hrl").

one_hot_one_pos([])    -> <<>>;
one_hot_one_pos([H|T]) ->
  Rest = one_hot_one_pos(T),
  if
    (H == 1) -> << 1:1, Rest/bitstring >>;
    (H /= 1) -> << 0:1, Rest/bitstring >>
  end.

flatten(#node{ left_child  = LChild
             , right_child = RChild
             , coeffs      = Coeffs
             , bias        = Bias
             },
        CoeffRes) ->
  OnePos = one_hot_one_pos(Coeffs),
  FracCoeffs = [ X || X <- Coeffs, X /= 1],
  Quantized  = lists:map(fun(X) -> round(X * (1 bsl (CoeffRes-1))) end, 
                         FracCoeffs),
  % io:write(io:format("~p", [Quantized])),
  CoeffBits  = << << X:CoeffRes >> || X <- Quantized >>, 
  << LChild:1
   , RChild:1
   , OnePos/bitstring
   , CoeffBits/bitstring
   , Bias:10
   , 0:1
  >>;
flatten(Tree, CoeffRes) ->
  L = [ flatten(V, CoeffRes) || {_, V} <- gb_trees:to_list(Tree) ],
  << << X/bitstring >> || X <- L >>.

