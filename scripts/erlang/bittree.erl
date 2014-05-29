-module(bittree).
-export([flatten/2]).

-include_lib("include/noderec.hrl").

flatten(#node{ left_child  = LChild
             , right_child = RChild
             , coeffs      = Coeffs
             , bias        = Bias
             },
        CoeffRes) ->
  OnePos = string:str(Coeffs, [0])-1,
  FracCoeffs = [ X || X <- Coeffs, X /= 1],
  Quantized  = lists:map(fun(X) -> round(X * (1 bsl CoeffRes)) end, 
                         FracCoeffs),
  CoeffBits  = << << X:CoeffRes >> || X <- Quantized >>, 
  << LChild:1
   , RChild:1
   , OnePos:(length(Coeffs))
   , CoeffBits/bitstring
   , Bias:10
   , 0:1
  >>;
flatten(Tree, CoeffRes) ->
  L = [ flatten(V, CoeffRes) || {_, V} <- gb_trees:to_list(Tree) ],
  << << X/bitstring >> || X <- L >>.

