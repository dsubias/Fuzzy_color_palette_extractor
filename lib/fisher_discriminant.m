function [J, Jmax, JmaxPos] = fisher_discriminant(V)
% FISHER_DISCRIMINANT Implementation of Fisher's Linear Discriminant
%
% Used to find the optimal cut-off threshold for relevance metrics as explained in:
% PEER GROUP FILTERING AND PERCEPTUAL COLOR IMAGE QUANTIZATION, 
% Y. Deng, C. Kenney, M.S. Moore, B.S. Manjunath

    N = length(V);
    a1 = zeros(1, N);
    a2 = zeros(1, N);
    s1 = zeros(1, N);
    s2 = zeros(1, N);
    J = zeros(1, N);

    % Calculate Fisher's criterion for each possible split point
    for i = 2:N
        a1(i) = sum(V(1:(i-1))) / (i-1);
        a2(i) = sum(V(i:N)) / (N+1-i);
        s1(i) = sum((V(1:(i-1)) - a1(i)).^2);
        s2(i) = sum((V(i:N) - a2(i)).^2);
        
        % Compute discriminant (prevent division by zero mathematically)
        J(i) = (a1(i) - a2(i)).^2 / (s1(i) + s2(i) + eps);
    end

    J = J(2:N);
    Jmax = max(J);
    JmaxPos = find(J == Jmax, 1);
end
