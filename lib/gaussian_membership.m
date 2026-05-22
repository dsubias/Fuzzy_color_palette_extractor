function membershipValue = gaussian_membership(x, center, spread)
% EXP Computes a Gaussian membership function.
%
%   membershipValue = gaussian_membership(x, center, spread)
%
%   Inputs:
%       x      - Input value(s) to evaluate.
%       center - The center (mean) of the Gaussian function.
%       spread - The spread (standard deviation) of the Gaussian function.
%
%   Outputs:
%       membershipValue - The computed membership degree in the range (0, 1].

    % Calculate the Gaussian exponential membership value
    membershipValue = exp(-(center - x).^2 / (spread^2));
end