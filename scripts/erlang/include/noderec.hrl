% noderec.hrl
% Definition for a decision tree node as represented in Erlang.
-record(node, { left_child  = 0
              , right_child = 0
              , coeffs      = [1, 0, 0]
              , bias        = 0
              }).
