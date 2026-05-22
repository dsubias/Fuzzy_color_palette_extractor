function [distC2U, distU2C, finalMetric] = compute_perceptual_metrics(centroids, userColors, fid)
% COMPUTE_PERCEPTUAL_METRICS Computes perceptual distances between extracted colors and user colors.
%
% Inputs:
%   centroids  - Colors extracted by the algorithm (Nx3 LAB matrix)
%   userColors - Colors selected by human observers (Mx3 LAB matrix)
%   fid        - File identifier for logging the metrics output
%
% Outputs:
%   distC2U    - Array of minimum distances from each centroid to user colors
%   distU2C    - Array of minimum distances from each user color to centroids
%   finalMetric- The combined average perceptual distance metric

    addpath('./lib');
    
    %% Compute Centroid -> User Distances
    % For each centroid, find the closest user color
    distC2U = calculate_minimum_distances(centroids, userColors);
    
    fprintf(fid, 'Distance centroids to all users: %.4f\n', sum(distC2U));
    fprintf(fid, 'Distance centroids to all user mean: %.4f\n\n', mean(distC2U));
    
    %% Compute User -> Centroid Distances
    % For each user color, find the closest centroid
    distU2C = calculate_minimum_distances(userColors, centroids);
    
    fprintf(fid, 'Distance users to all centroids: %.4f\n', sum(distU2C)); 
    fprintf(fid, 'Distance users to all centroids mean: %.4f\n\n', mean(distU2C)); 

    %% Compute Final Metrics
    totalSum = sum(distC2U) + sum(distU2C);
    totalMean = mean(distC2U) + mean(distU2C);
    
    fprintf(fid, 'Total Distance: %.4f\n', totalSum);
    fprintf(fid, 'Total Distance mean: %.4f\n\n', totalMean);
    
    finalMetric = totalMean;
end

function minDists = calculate_minimum_distances(sourceColors, targetColors)
% Calculates the minimum Delta E00 perceptual distance from each source color
% to any target color in the provided set.

    numSource = size(sourceColors, 1);
    numTarget = size(targetColors, 1);
    minDists = zeros(numSource, 1);
    
    for i = 1:numSource
        % Extract current source color
        currentSource = sourceColors(i, :);
        
        % Replicate to match target matrix size for vectorized deltaE00 evaluation
        sourceMatrix = repmat(currentSource, numTarget, 1);
        
        % Calculate perceptual distance from current source to all targets
        distsToTargets = deltaE00_mod(sourceMatrix, targetColors);
        
        % The perceptual distance is the minimum distance to a match
        minDists(i) = min(distsToTargets);
    end
end
