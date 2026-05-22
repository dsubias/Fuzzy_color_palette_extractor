function relevanceValue = fuzzy_system(probability, lightness, chroma, showGraphics, colorIdx)
% FUZZY_SYSTEM Computes the relevance of a color based on a fuzzy logic system.
%
%   relevanceValue = fuzzy_system(probability, lightness, chroma, showGraphics, colorIdx)
%
%   Inputs:
%       probability  - Probability/frequency of the color in the image.
%       lightness    - The L* component (lightness) of the color in CIELAB space.
%       chroma       - The calculated chroma (sqrt(a^2 + b^2)) of the color.
%       showGraphics - Boolean flag to plot and save the defuzzification process.
%       colorIdx     - Identifier for the color (used for saving figures).
%
%   Outputs:
%       relevanceValue - The final computed relevance score for the color.

    %% 1. Define Fuzzy Membership Functions (Input Variables)
    
    % Probability (Frequency)
    paretoDist = makedist('GeneralizedPareto', 'k', 0, 'sigma', 1, 'theta', 0);
    is_high_probability = @(x) cdf(paretoDist, x);
    is_low_probability = @(x) fuzzy_triangle(x, 0.1, 4);

    % Chroma
    is_very_low_chroma = @(x) fuzzy_left_shoulder(x, 0.2);
    is_low_chroma = @(x) gaussian_membership(x, 0.25, 0.08);
    is_medium_chroma = @(x) gaussian_membership(x, 0.5, 0.1);
    is_high_chroma = @(x) gaussian_membership(x, 0.75, 0.08);
    is_very_high_chroma = @(x) fuzzy_right_shoulder(x, 0.8, 1);
    
    % Lightness (Luminance)
    is_very_low_lightness = @(x) fuzzy_left_shoulder(x, 0.3);
    is_low_lightness = @(x) gaussian_membership(x, 0.25, 0.07);
    is_medium_lightness = @(x) gaussian_membership(x, 0.5, 0.1);
    is_high_lightness = @(x) gaussian_membership(x, 0.75, 0.08);
    is_very_high_lightness = @(x) fuzzy_right_shoulder(x, 0.7, 1);

    %% 2. Evaluate Fuzzy Rules

    % --- Rules for HIGH Relevance ---
    highRelevanceRules = zeros(7, 1);
    
    % Rule 1: IF high probability AND low lightness THEN high relevance
    highRelevanceRules(1) = is_high_probability(probability) * is_low_lightness(lightness);

    % Rule 2: IF high probability AND very low lightness THEN high relevance
    highRelevanceRules(2) = is_high_probability(probability) * is_very_low_lightness(lightness);

    % Rule 3: IF high probability AND medium lightness THEN high relevance
    highRelevanceRules(3) = is_high_probability(probability) * is_medium_lightness(lightness);

    % Rule 4: IF (high OR low probability) AND high lightness THEN high relevance
    highRelevanceRules(4) = max(is_high_probability(probability), is_low_probability(probability)) * is_high_lightness(lightness);

    % Rule 5: IF (high OR low probability) AND very high lightness THEN high relevance
    highRelevanceRules(5) = max(is_high_probability(probability), is_low_probability(probability)) * is_very_high_lightness(lightness);

    % Rule 6: IF (high OR low probability) AND very high chroma THEN high relevance
    highRelevanceRules(6) = max(is_high_probability(probability), is_low_probability(probability)) * is_very_high_chroma(chroma);

    % Rule 7: IF (high OR low probability) AND high chroma THEN high relevance
    highRelevanceRules(7) = max(is_high_probability(probability), is_low_probability(probability)) * is_high_chroma(chroma);

    % Aggregate HIGH rules (Fuzzy OR operator)
    valHighRelevance = max(highRelevanceRules);
    
    
    % --- Rules for LOW Relevance ---
    lowRelevanceRules = zeros(4, 1);

    % Rule 1: IF low probability AND low lightness AND low chroma THEN low relevance
    lowRelevanceRules(1) = is_low_probability(probability) * is_low_lightness(lightness) * is_low_chroma(chroma);
    
    % Rule 2: IF low probability AND low lightness AND very low chroma THEN low relevance
    lowRelevanceRules(2) = is_low_probability(probability) * is_low_lightness(lightness) * is_very_low_chroma(chroma);

    % Rule 3: IF low probability AND very low lightness AND very low chroma THEN low relevance
    lowRelevanceRules(3) = is_low_probability(probability) * is_very_low_lightness(lightness) * is_very_low_chroma(chroma);

    % Rule 4: IF low probability AND very low lightness AND low chroma THEN low relevance
    lowRelevanceRules(4) = is_low_probability(probability) * is_very_low_lightness(lightness) * is_low_chroma(chroma);

    % Aggregate LOW rules (Fuzzy OR operator)
    valLowRelevance = max(lowRelevanceRules);


    % --- Rules for MEDIUM Relevance ---
    mediumRelevanceRules = zeros(2, 1);
    
    % Rule 1: IF low probability AND medium lightness AND (medium OR high chroma) THEN medium relevance
    mediumRelevanceRules(1) = is_low_probability(probability) * is_medium_lightness(lightness) * max(is_medium_chroma(chroma), is_high_chroma(chroma));
    
    % Rule 2: IF high probability AND low chroma THEN medium relevance
    mediumRelevanceRules(2) = is_high_probability(probability) * is_low_chroma(chroma);
    
    % Aggregate MEDIUM rules (Fuzzy OR operator)
    valMediumRelevance = max(mediumRelevanceRules);


    %% 3. Defuzzification (Center of Gravity)
    
    % Define the output range for relevance [0, 1]
    relevanceRange = linspace(0, 1, 1000);
    
    % Output Membership Functions
    mfLow = fuzzy_left_shoulder(relevanceRange, 0.6);
    mfMedium = gaussian_membership(relevanceRange, 0.5, 0.125);
    mfHigh = fuzzy_right_shoulder(relevanceRange, 0.4, 1);
    
    % Clip output functions by rule activation values
    clippedLow = min(mfLow, valLowRelevance);
    clippedMedium = min(mfMedium, valMediumRelevance);
    clippedHigh = min(mfHigh, valHighRelevance);
    
    % Combine all clipped functions into the final fuzzy set
    combinedOutput = max(max(clippedLow, clippedMedium), clippedHigh);
    
    % Calculate Center of Gravity (Centroid)
    relevanceValue = sum(combinedOutput .* relevanceRange) / sum(combinedOutput);
    
    % Handle potential division by zero if all rules returned 0
    if isnan(relevanceValue)
        relevanceValue = 0;
    end
    
    %% 4. Plot Graphics (Optional)
    
    if showGraphics
        % Ensure the figures directory exists
        if ~exist('figures', 'dir')
            mkdir('figures');
        end
        
        figFuzzy = figure('Visible', 'off');
        hold on;
        
        % Plot the combined fuzzy output shape
        plot(relevanceRange, combinedOutput, 'LineWidth', 1.5, 'Color', [0.2 0.6 0.8]);
        
        % Mark the defuzzified centroid result
        scatter(relevanceValue, 0, 80, 'red', 'filled');
        
        title(sprintf('Defuzzification Area (Color ID: %d)', colorIdx));
        xlabel('Relevance');
        ylabel('Membership Degree');
        grid on;
        
        saveas(figFuzzy, sprintf('figures/color_%d.jpeg', colorIdx));
        close(figFuzzy);
    end
end
