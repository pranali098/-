clc; clear all; close all;
% --- Radar Parameters ---
Nr = 60; % Number of range bins (height)
Nc = 100; % Number of chirps (width)
A = 1.0; % Amplitude
center_range = 50; % Center in range
center_chirp = 90; % Center in chirps
B = 200e6; % Bandwidth in Hz..........covenient unit
c = 3e8; % Speed of light (m/s)
range_resolution = c / (2 * B); % Range resolution
disp(['Range Resolution (Range Bin Size): ', num2str(range_resolution), ' meters']);

% --- Vehicle Target Parameters ---
% Adjust these parameters to reflect a typical vehicle size
spread_range_vehicle = 7;   % Larger spread in range (height) for a vehicle
spread_chirp_vehicle = 15;  % Larger spread in chirps (width) for a vehicle

% --- Noise Parameters --
noise_level = 0.10;

% --- Create Meshgrid ---
[range_bins, chirps] = meshgrid(1:Nr, 1:Nc);
range_bins = range_bins';
chirps = chirps';

% --- Generate Gaussian Vehicle Target ---
% Use the updated spread parameters for the vehicle target
vehicle_signal = A .* exp(-((chirps - center_chirp).^2 / (2 * spread_chirp_vehicle.^2)) - ((range_bins - center_range).^2 / (2 * spread_range_vehicle.^2)));

% --- Add Noise ---
noise = noise_level * randn(Nr, Nc);
range_time_map = vehicle_signal + noise;

% --- Thresholding ---
threshold_factor = 3;
threshold = mean(range_time_map(:)) + threshold_factor * std(range_time_map(:));
detected_vehicle = range_time_map > threshold;

% --- Morphological Operations (Cleaning) ---
se = strel('disk', 3); % Keep the structuring element the same or adjust based on expected vehicle shape
detected_vehicle_cleaned = imopen(detected_vehicle, se);
detected_vehicle_cleaned = imclose(detected_vehicle, se);

% --- Target Centroid Detection ---
stats = regionprops(detected_vehicle_cleaned, 'Centroid');
if ~isempty(stats)
    detected_center_chirp = round(stats(1).Centroid(1)); % Centroid is (column, row) = (Chirp, Range Bin)
    detected_center_range = round(stats(1).Centroid(2));
    disp(['Vehicle detected near Range Bin: ', num2str(detected_center_range), ', Chirp: ', num2str(detected_center_chirp)]);
else
    disp('No vehicle detected based on the threshold.');
end

% --- Plotting ---
figure('Position', [100, 100, 800, 400]);

% Subplot 1 - Original Range-Time Map
subplot(1, 2, 1);
imagesc(1:Nc, 1:Nr, range_time_map); % Chirps on x, Range Bins on y
colormap(parula); % Apply 'parula' colormap for colorful visualization
colorbar;
%caxis([-0.25, 1.0]); % Adjust color limits to match the scale
xlabel('Chirps');
ylabel('Range Bin');
title(' tactical vehicle');
ax1 = gca; % Get the handle to the current axes
set(ax1, 'YDir', 'normal');  % ✅ Fix: Make Y-axis go from 0 to 60 (bottom to top)
set(ax1, 'YLim', [0, Nr]);
set(ax1, 'YTick', 0:10:Nr);
set(ax1, 'XLim', [0, Nc]);
set(ax1, 'XTick', 0:20:Nc);
hold on;
if ~isempty(stats)
    plot(detected_center_chirp, detected_center_range, 'MarkerSize', 10, 'LineWidth', 2);
end
hold off;

% Subplot 2 - Detected Tank (Colorful)
subplot(1, 2, 2);
imagesc(1:Nc, 1:Nr, detected_tank_cleaned); % Convert logical matrix to double for color mapping
colormap(parula); % ✅ Apply 'parula' colormap for colors
colorbar;
xlabel('Chirps');
ylabel('Range Bin');
title(' tactical vehicle');
