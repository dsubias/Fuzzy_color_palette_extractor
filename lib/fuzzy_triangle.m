function membershipValue = fuzzy_triangle(x, b, c)
% FUZZY_TRIANGLE Computes a triangular/piecewise linear membership function.
%
%   membershipValue = fuzzy_triangle(x, b, c)
%
%   Inputs:
%       x - Input value(s) to evaluate.
%       b - The peak point where the membership value is 1.
%       c - The end point where the membership value drops to 0.
%
%   Outputs:
%       membershipValue - The computed membership degree.
%                         It linearly increases from 0 to 1 between x=0 and x=b,
%                         and linearly decreases to 0 between x=b and x=c.

    membershipValue = x;
    membershipValue(x <= b) = x(x <= b) / b;
    
    idx = (x > b) & (x < c);
    membershipValue(idx) = 1 - (x(idx) / c);
    
    membershipValue(x >= c) = 0;
end