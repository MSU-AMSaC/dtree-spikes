-module(coeff_tree).
-export([build_tree/0]).
-include_lib("include/noderec.hrl").

build_tree() ->
  gb_trees:from_orddict(
    [ 
    {1, #node{ left_child  = 0
             , right_child = 1
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
             , coeffs      = [0, 0, 1]
             , bias        = -18
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
  
