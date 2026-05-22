clc;
clear;
close all;

% Add library functions to the path
addpath('./lib');

% --- Configuration Parameters ---
maxIterations = 5;               % Maximum number of pruning iterations
experimentName = 'adaptive_2_iters'; % Name of the experiment directory
useAdaptive = true;              % Whether to use adaptive stopping criteria
numInitialColors = 50;           % Number of initial colors for K-means
plotFigures = true;              % Whether to generate and save plots

rng(0);                          % Set random seed for reproducibility
gpuDevice(1);                    % Select the first available GPU (if applicable)

% --- Setup Directories ---
% Create necessary directories to store the experiment's results
directories = {experimentName, ...
    fullfile(experimentName, 'plots'), ...
    fullfile(experimentName, 'reconstruction'), ...
    fullfile(experimentName, 'original'), ...
    fullfile(experimentName, 'k_means'), ...
    fullfile(experimentName, 'color_palettes')};

for i = 1:length(directories)
    if ~exist(directories{i}, 'dir')
        mkdir(directories{i});
    end
end

% --- Initialization of Metric Trackers ---
mseList = [];
maeList = [];
psnrList = [];
ssimList = [];
numRelevantColorsList = [];

% Open a file to store the metrics
metricsFile = fullfile(experimentName, sprintf('metrics_%s_%d.txt', experimentName, maxIterations));
fid = fopen(metricsFile, 'w');
if fid == -1
    error('Error opening metrics file: %s', metricsFile);
end

% --- Image Retrieval ---
folderPath = './Test_Images';

% Get information for all .jpg and .png files (case-insensitive)
files = [dir(fullfile(folderPath, '*.JPG')); ...
    dir(fullfile(folderPath, '*.jpg')); ...
    dir(fullfile(folderPath, '*.PNG')); ...
    dir(fullfile(folderPath, '*.png'))];

% Extract and sort file names to ensure consistency
imageNames = sort({files.name}');
disp('Files to be processed:');
disp(imageNames);

totalImages = numel(files);
fprintf('Total images found: %d\n', totalImages);

%% --- Main Processing Loop ---

for imgIdx = 1:totalImages
    
    numRelevantColors = inf;
    
    fprintf(fid, 'Painting: %d\n', imgIdx);
    fprintf('Painting: %d\n', imgIdx);
    
    fullPath = fullfile(files(imgIdx).folder, files(imgIdx).name);
    
    % Read image and its size
    img = imread(fullPath);
    imgSize = size(img);
    
    % Skip grayscale/black-and-white images
    if numel(imgSize) < 3 || imgSize(3) == 1
        fprintf(fid, 'Skipping Image %d (%s): Black and White detected.\n\n', ...
            imgIdx, files(imgIdx).name);
        continue;
    end
    
    imgHeight = imgSize(1);
    imgWidth = imgSize(2);
    fprintf('Image %d: %s | Size: %d x %d x %d\n', ...
        imgIdx, files(imgIdx).name, imgHeight, imgWidth, imgSize(3));
    
    % Save original image
    originalPath = fullfile(experimentName, 'original', sprintf('khan_original_%d.jpg', imgIdx));
    imwrite(img, originalPath);
    
    %% Compute K-means to split the image into regions
    
    imgLab = rgb2lab(img);
    
    fprintf('Computing K-means...\n');
    [pixelLabels, colorCenters] = imsegkmeans(im2single(imgLab), numInitialColors);
    
    % Calculate the probability (frequency) of each cluster
    pixelIndices = reshape(pixelLabels, [imgHeight * imgWidth, 1]);
    
    % Using a hidden figure to efficiently compute histogram values
    hFig = figure('Visible', 'off');
    h = histogram(pixelIndices, 'Normalization', 'probability');
    clusterProbabilities = h.Values';
    close(hFig);
    
    % Save K-means visualization
    labeledImage = colorCenters(pixelIndices, :);
    kmeansImagePath = fullfile(experimentName, 'k_means', sprintf('k_means_%d.jpg', imgIdx));
    imwrite(lab2rgb(reshape(labeledImage, [imgHeight, imgWidth, 3])), kmeansImagePath);
    
    % Convert probabilities to percentages and extract LAB characteristics
    probPercent = clusterProbabilities * 100;
    chromaVal = sqrt(colorCenters(:,2).^2 + colorCenters(:,3).^2) / 100.0;
    lightnessVal = colorCenters(:,1) / 100.0;
    
    %% Compute Fuzzy System to calculate color relevances
    
    fprintf('Running Fuzzy System...\n');
    colorRelevances = zeros(numInitialColors, 1);
    
    for i = 1:numInitialColors
        [colorRelevances(i,1)] = fuzzy_system(probPercent(i), lightnessVal(i), chromaVal(i), 0, i);
    end
    
    %% Select Most Relevant Colors using recursive pruning
    
    finalRelevances = colorRelevances;
    finalColors = colorCenters;
    finalProbabilities = probPercent;
    
    for iteration = 1:maxIterations
        
        fprintf('Iteration %d: current relevant colors %d\n', iteration, numRelevantColors);
        
        % Check stopping conditions
        if (numRelevantColors <= 30 && useAdaptive) || numRelevantColors == 1
            iteration = iteration - 1;
            break;
        end
        
        % Sort by relevance
        [sortedRelevances, sortIndex] = sort(finalRelevances);
        
        % Identify the largest drop (knee point) to filter out irrelevant colors
        [~, ~, dropPos] = fisher_discriminant(sortedRelevances);
        
        % Keep only the most relevant colors
        finalRelevances = sortedRelevances(dropPos + 1 : end);
        
        % Apply the same sorting and pruning to the colors array
        sortedColors = finalColors(sortIndex, :);
        finalColors = sortedColors(dropPos + 1:end, :);
        
        numRelevantColors = size(finalColors, 1);
        relevanceStats = zeros(numRelevantColors, 5);
        
        % Prune probabilities as well
        sortedProbabilities = finalProbabilities(sortIndex);
        finalProbabilities = sortedProbabilities(dropPos + 1:end);
        relevanceStats(:, 1) = finalProbabilities;
        
    end
    
    %% Post-processing Stats & Metrics calculation
    
    % Recalculate Chroma and Lightness for the remaining colors
    finalChroma = sqrt(finalColors(:,2).^2 + finalColors(:,3).^2) / 100;
    relevanceStats(:, 2) = finalChroma;
    
    finalLightness = finalColors(:,1);
    relevanceStats(:, 3) = finalLightness;
    
    relevanceStats(:, 4) = finalRelevances;
    
    % Scaled probabilities for plotting point sizes
    relevanceStats(:, 5) = relevanceStats(:, 1) * 15;
    
    fprintf('Computing Metrics...\n');
    fprintf(fid, 'Ours:\n');
    fprintf(fid, 'Num relevant colors: %d\n', numRelevantColors);
    
    %% Reconstruct Image and Compute Quality Metrics
    
    imgFlattened = reshape(imgLab, [imgHeight * imgWidth, 3]);
    reconstructedImagePath = fullfile(experimentName, 'reconstruction', sprintf('relvant_colors_image_%d_%d.jpg', imgIdx, iteration));
    
    reconstructedImage = paint_image(finalColors, imgFlattened, imgHeight, imgWidth, numRelevantColors, reconstructedImagePath);
    
    % Calculate comparison metrics
    originalImgDouble = reshape(lab2rgb(imgLab), [imgHeight, imgWidth, 3]);
    mseVal = immse(originalImgDouble, reconstructedImage);
    maeVal = meanAbsoluteError(originalImgDouble, reconstructedImage);
    psnrVal = psnr(reconstructedImage, originalImgDouble);
    ssimVal = ssim(reconstructedImage, originalImgDouble);
    
    % Store metrics for computing averages
    mseList = [mseList; mseVal];
    maeList = [maeList; maeVal];
    psnrList = [psnrList; psnrVal];
    ssimList = [ssimList; ssimVal];
    numRelevantColorsList = [numRelevantColorsList; numRelevantColors];
    
    fprintf(fid, 'mse ours, %.4f\n', mseVal);
    fprintf(fid, 'mae ours, %.4f\n', maeVal);
    fprintf(fid, 'psnr ours, %.4f\n', psnrVal);
    fprintf(fid, 'ssim ours, %.4f\n\n', ssimVal);
    
    %% Generate and Save Color Palette Strip
    
    squareSize = 256;
    paletteStrip = zeros(squareSize, squareSize * numRelevantColors, 3, 'uint8');
    
    for cIdx = 1:numRelevantColors
        % Convert the individual lab color back to RGB (Range: [0, 1])
        currentLabColor = finalColors(cIdx, :);
        currentRgbColor = lab2rgb(currentLabColor);
        
        % Replicate the color across the full 256x256 square
        colorSquare = repmat(reshape(currentRgbColor, [1, 1, 3]), squareSize, squareSize);
        
        % Calculate column bounds and insert the square into the horizontal strip
        startCol = (cIdx - 1) * squareSize + 1;
        endCol = cIdx * squareSize;
        paletteStrip(:, startCol:endCol, :) = im2uint8(colorSquare);
    end
    
    % Save the palette strip image
    stripFilename = fullfile(experimentName, 'color_palettes', sprintf('palette_strip_%d.png', imgIdx));
    imwrite(paletteStrip, stripFilename);
    fprintf('Saved color palette strip to %s\n', stripFilename);
    
    %% Plot Data if enabled
    
    if plotFigures
        % a* vs b* Plot
        figAb = figure('Visible', 'off');
        hold on;
        scatter(finalColors(:,2), finalColors(:,3), relevanceStats(:,1) * 15, lab2rgb(finalColors), 'filled');
        ylabel('$b^*$', 'Interpreter', 'latex');
        xlabel('$a^*$', 'Interpreter', 'latex');
        title('Ours');
        
        abPlotPath = fullfile(experimentName, 'plots', sprintf('ours_vs_all_a_b_%d_%d', imgIdx, iteration));
        saveas(figAb, [abPlotPath, '.svg']);
        saveas(figAb, [abPlotPath, '.png']);
        close(figAb);
        
        % Lightness vs Chroma Plot
        figLc = figure('Visible', 'off');
        hold on;
        scatter(finalColors(:,1), finalChroma, relevanceStats(:,1) * 15, lab2rgb(finalColors), 'filled');
        ylabel('$C$', 'Interpreter', 'latex');
        xlabel('$L$', 'Interpreter', 'latex');
        title('Ours');
        
        lcPlotPath = fullfile(experimentName, 'plots', sprintf('ours_vs_all_L_C_%d_%d', imgIdx, iteration));
        saveas(figLc, [lcPlotPath, '.svg']);
        saveas(figLc, [lcPlotPath, '.png']);
        close(figLc);
    end
end

%% --- Final Averages and Formatting ---

avgMse = mean(mseList);
stdMse = std(mseList);

avgMae = mean(maeList);
stdMae = std(maeList);

avgPsnr = mean(psnrList);
stdPsnr = std(psnrList);

avgSsim = mean(ssimList);
stdSsim = std(ssimList);

avgNrc = mean(numRelevantColorsList);
stdNrc = std(numRelevantColorsList);

% Write final results into the output metrics file
fprintf(fid, '-------------------------------------------\n');
fprintf(fid, 'FINAL RESULTS (Across all valid paintings):\n');

fprintf(fid, 'mse ours:  %.4f (std: %.4f)\n', avgMse, stdMse);
fprintf(fid, 'mae ours:  %.4f (std: %.4f)\n', avgMae, stdMae);
fprintf(fid, 'psnr ours: %.4f (std: %.4f)\n', avgPsnr, stdPsnr);
fprintf(fid, 'ssim ours: %.4f (std: %.4f)\n', avgSsim, stdSsim);
fprintf(fid, 'NRC ours:  %.4f (std: %.4f)\n\n', avgNrc, stdNrc);

fclose(fid);
fprintf('Processing completed successfully.\n');
