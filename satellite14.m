%% ntn_satellite_slicing_combined.m
%
% This script combines a detailed satellite scenario (from Script 1) with
% a dynamic, time-based network slice performance simulation (from Script 2).
%
% It simulates three slices (eMBB, URLLC, mMTC) assigned to three
% different satellites, all communicating with a single ground station.
%
% The simulation calculates dynamic throughput and latency based on:
%   1. Real satellite access (visibility) to the ground station.
%   2. Priority-based resource allocation (URLLC > eMBB > mMTC).
%   3. Simulated link quality (randomized) *only* when access is available.
%

clc;
clear;
close all;

%% ---------- Check Toolbox ----------
v = ver;
hasSatToolbox = any(contains({v.Name}, 'Satellite Communications Toolbox'));
if ~hasSatToolbox
    error(['Satellite Communications Toolbox not found. '...
           'This script requires it to run. '...
           'Install it via Home -> Add-Ons -> Get Add-Ons.']);
end

%% ---------- 1. Create Satellite Scenario (from Script 1) ----------
% Scenario: 1 hour duration, 10 s sample time
sc = satelliteScenario(datetime(2025,11,29,23,0,0), ...
                       datetime(2025,11,30,0,0,0), ...
                       10); % Use 10s sample time for higher resolution

%% ---------- 2. Add Ground Station (from Script 1) ----------
% Ground station: Cleveland, OH
gs = groundStation(sc, 41.5, -81.7, ...
    'Name','Cleveland GS', ...
    'MinElevationAngle', 5);

%% ---------- 3. Add Satellites (from Script 1) ----------
% Orbit parameters (LEO, circular)
earthRadius_km = 6371;      % km
altitude_km    = 700;       % km
a_km           = earthRadius_km + altitude_km; % 7071 km
ecc            = 0;
inc_deg        = 55;
RAANs_deg      = [0, 60, 120];
trueAnoms_deg  = [0, 30, 60];

% Slice satellites: eMBB, URLLC, mMTC
sliceNames  = ["eMBB","URLLC","mMTC"];
sliceColors = {'red','green','blue'};

% Pre-allocation for MATLAB version compatibility
sliceSats(1) = satellite(sc, ...
    a_km * 1000, ecc, inc_deg, RAANs_deg(1), 0, trueAnoms_deg(1), ...
    'Name', sliceNames(1));
sliceSats = repmat(sliceSats(1), 1, 3);
for k = 2:3
    sliceSats(k) = satellite(sc, ...
        a_km * 1000, ecc, inc_deg, RAANs_deg(k), 0, trueAnoms_deg(k), ...
        'Name', sliceNames(k));
end

%% ---------- 4. Access Analysis (from Script 1) ----------
% Create access objects for all three satellites to the one ground station
acc = access(sliceSats, gs);

%% ---------- 5. Define Network Slices & Sim Parameters (from Script 2) ----------
% Define slice properties (name, priority)
slices(1).name = sliceNames(1); slices(1).priority = 3; % eMBB (Broadband)
slices(2).name = sliceNames(2); slices(2).priority = 5; % URLLC (MissionCritical)
slices(3).name = sliceNames(3); slices(3).priority = 1; % mMTC (IoT)
totalPriority = sum([slices.priority]);

% System parameters
totalBW_MHz = 50;
spectralEfficiency_bpsHz = 2; % bits/s/Hz

% Simulation time vector based on the scenario
timeVec = sc.StartTime:seconds(sc.SampleTime):sc.StopTime;
N = numel(timeVec);

% Pre-allocate results matrices
throughput_Mbps = zeros(N,length(slices));
latency_ms = zeros(N,length(slices));
fprintf('Running dynamic simulation for %d time steps...\n', N);

%% ---------- 6. Combined Simulation Loop (NEW) ----------
% This loop uses the 'access' object from step 4 to drive the
% simulation logic from Script 2.

for k = 1:N
    currentTime = timeVec(k);

    % 1. Check access status for all 3 satellites at this time step
    inView = false(1,3);
    linkQuality = zeros(1,3);
    for s = 1:3
        [status, ~] = accessStatus(acc(s), currentTime);
        if status
            inView(s) = true;
            % Simulate a variable link quality (e.g., 50% to 100%)
            linkQuality(s) = 0.5 + rand() * 0.5;
        end
    end

    % 2. Calculate dynamic resource allocation
    % Find total priority *only* of satellites currently in view
    activePriorities = [slices(inView).priority];
    totalActivePriority = sum(activePriorities);

    if totalActivePriority == 0
        % No satellites in view, all performance is zero
        throughput_Mbps(k,:) = 0;
        latency_ms(k,:) = NaN; % Use NaN to create gaps in the plot
        continue;
    end

    % 3. Allocate resources and calculate KPIs for visible slices
    for s = 1:3
        if inView(s)
            % This slice's share of the *available* priority pool
            priorityShare = slices(s).priority / totalActivePriority;

            % Allocate bandwidth based on priority, then degrade by link quality
            alloc_MHz = totalBW_MHz * priorityShare * linkQuality(s);

            % Calculate throughput (based on Script 2's formula)
            throughput_Mbps(k,s) = alloc_MHz * 1e6 * spectralEfficiency_bpsHz / 1e6;

            % Calculate latency (based on Script 2's formula)
            % Latency increases as link quality (0.5-1.0) decreases
            latency_ms(k,s) = 20 + 200*(1-linkQuality(s)) + randn()*5;
        else
            % This satellite has no access
            throughput_Mbps(k,s) = 0;
            latency_ms(k,s) = NaN;
        end
    end
end
fprintf('Simulation complete.\n');

%% ---------- 7. Plotting - ALL Graphs ----------

%% PLOT 1: 3D Scenario Viewer (from Script 1)
fprintf('Opening satellite scenario viewer...\n');
viewer = satelliteScenarioViewer(sc, 'ShowDetails', true);
campos(viewer, [2.0e4, 2.0e4, 1.2e4]);
% Optional: play the animation
% play(sc);

%% PLOT 2: Access Intervals (from Script 1)
figure('Name','Access Intervals','NumberTitle','off', 'Position', [100, 100, 800, 600]);
for k = 1:numel(sliceSats)
    [intv, ~] = accessIntervals(acc(k));
    subplot(3,1,k);
    if ~isempty(intv)
        starts = intv.StartTime;
        stops  = intv.EndTime;
        hold on;
        for j = 1:numel(starts)
            rectangle('Position',[datetime(starts(j)), 0.5, ...
                datetime(stops(j))-datetime(starts(j)), 0.5], ...
                'FaceColor', sliceColors{k}, 'EdgeColor', 'none');
        end
        dateTickPicker('x','HH:MM');
        ylim([0 1.5]);
        ylabel(char(sliceNames(k)));
        title(sprintf('Access windows: %s -> Cleveland GS', sliceNames(k)));
        grid on;
        set(gca, 'YTick', []);
    else
        text(0.5,0.5,'No access within scenario window','HorizontalAlignment','center');
        title(sprintf('Access windows: %s -> Cleveland GS', sliceNames(k)));
        axis off;
    end
end
sgtitle('Satellite-to-Ground Station Access Windows');

%% PLOT 3: Static Illustrative KPIs (from Script 1)
slices_static     = sliceNames;
totalCap   = 20; % Illustrative total
share      = [0.6 0.25 0.15]; % Illustrative shares
capacity   = totalCap * share;
latency_ms_static = [40 15 100];
pktLoss_pc = [1 0.5 3];

figure('Name','NTN RAN Slicing Target KPIs','NumberTitle','off', 'Position', [150, 150, 800, 700]);
subplot(3,1,1); bar(slices_static, capacity);
ylabel('Throughput (Mbps)'); title('Target Throughput per Slice'); grid on;
subplot(3,1,2); bar(slices_static, latency_ms_static);
ylabel('Latency (ms)'); title('Target Latency per Slice'); grid on;
subplot(3,1,3); bar(slices_static, pktLoss_pc);
ylabel('Packet Loss (%)'); title('Target Packet Loss per Slice'); grid on;
sgtitle('NTN RAN Network Slicing KPIs (Illustrative Targets)');

%% PLOT 4: Dynamic Simulated Throughput (from Script 2, improved)
figure('Name','Dynamic Simulated Throughput','NumberTitle','off', 'Position', [200, 200, 900, 400]);
plot(timeVec, throughput_Mbps, 'LineWidth', 2);
grid on;
xlabel('Time (UTC)');
ylabel('Throughput (Mbps)');
title('Dynamic Simulated Throughput per Slice');
legend({slices.name},'Location','best');
dateTickPicker('x', 'HH:MM', 'keeplimits');

%% PLOT 5: Dynamic Simulated Latency (NEW, from Script 2 logic)
figure('Name','Dynamic Simulated Latency','NumberTitle','off', 'Position', [250, 250, 900, 400]);
plot(timeVec, latency_ms, 'LineWidth', 2);
grid on;
xlabel('Time (UTC)');
ylabel('Latency (ms)');
title('Dynamic Simulated Latency per Slice (during access)');
legend({slices.name},'Location','best');
datetickpicker('x', 'HH:MM', 'keeplimits');
fprintf('All plots generated.\n');