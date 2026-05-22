function membershipValue = fuzzy_left_shoulder(x, b)
% FUZZY_LEFT_SHOULDER Computes a left-shoulder linear membership function.
%
%   membershipValue = fuzzy_left_shoulder(x, b)
%
%   Inputs:
%       x - Input value(s) to evaluate.
%       b - The point where the membership value drops to 0.
%
%   Outputs:
%       membershipValue - The computed membership degree in the range [0, 1].
%                         It is 1 at x=0 and linearly decreases to 0 at x=b.

    membershipValue = x;
    membershipValue(x <= b) = 1 - (x(x <= b) / b);
    membershipValue(x > b)  = 0;
end