function membershipValue = fuzzy_right_shoulder(x, b, maxValue)
% FUZZY_RIGHT_SHOULDER Computes a right-shoulder linear membership function.
%
%   membershipValue = fuzzy_right_shoulder(x, b, maxValue)
%
%   Inputs:
%       x        - Input value(s) to evaluate.
%       b        - The starting point where the membership value is 0.
%       maxValue - The point where the membership value reaches 1.
%
%   Outputs:
%       membershipValue - The computed membership degree in the range [0, 1].
%                         It is 0 for x <= b, and linearly increases to 1 at x=maxValue.

    membershipValue = x; % Initialize with same size/type as input
    membershipValue(x < b) = 0;
    
    % Ensure that we don't evaluate bounds out of the expected logic
    idx = (x >= b);
    membershipValue(idx) = (x(idx) - b) / (maxValue - b);
end