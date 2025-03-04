%% Load data and set sampling rate and binning factor

load('data/preprocessed.mat')

smoothing_factor = 2;

sampling_rate = 20000;
binsize_factor = 0.25;
%%

for k = 1 : length(analysis)
    analysis(k).xveloc_in_mm = analysis(k).VelocX(:,1)*8.79;
    analysis(k).zveloc_in_mm = analysis(k).VelocZ(:,1)*8.79;
    analysis(k).yveloc_in_mm = analysis(k).VelocY(:,1)*8.79;
    analysis(k).zveloc_in_degree_per_s = analysis(k).VelocZ(:,1)*158.9;
    analysis(k).yveloc_in_degree_per_s = analysis(k).VelocY(:,1)*158.9;
    analysis(k).motion = [analysis(k).VelocX, analysis(k).VelocY, analysis(k).VelocZ];
    analysis(k).VM_medfilt = medfilt1(analysis(k).VM,5000);
end


%% X velocity in mm binning

clearvars binstart binstarts binsize

binstarts=nan;
binsize = binsize_factor*sampling_rate;

for k = 1 : length(analysis)
    
    binstarts = 1:binsize:length(analysis(k).xveloc_in_mm);
    xvelocbinned=nan;
    for bin = 1 : length(binstarts)-1
        xvelocbinned(:,bin) = sum(analysis(k).xveloc_in_mm(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    xvelocbinned = xvelocbinned/binsize;
    analysis(k).xveloc_in_mm_binned = xvelocbinned;
    
end

%% Z velocity in mm/s binning

clearvars binstart binstarts binsize

binstarts = nan;
binsize = binsize_factor*sampling_rate;

for k = 1 : length(analysis)
    
    binstarts = 1:binsize:length(analysis(k).zveloc_in_mm);
    zvelocbinned=nan;
    for bin = 1 : length(binstarts)-1
        zvelocbinned(:,bin) = sum(analysis(k).zveloc_in_mm(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    zvelocbinned = zvelocbinned/binsize;
    analysis(k).zveloc_in_mm_binned = zvelocbinned;
    
end

%Z velocity in degree/s binning

clearvars binstart binstarts binsize zvelocbinned

binstarts = nan;
binsize = binsize_factor*sampling_rate;

for k = 1 : length(analysis)
    
    binstarts = 1:binsize:length(analysis(k).zveloc_in_degree_per_s);
    zvelocbinned=nan;
    for bin = 1 : length(binstarts)-1
        zvelocbinned(:,bin) = sum(analysis(k).zveloc_in_degree_per_s(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    zvelocbinned = zvelocbinned/binsize;
    analysis(k).zveloc_in_degree_per_s_binned = zvelocbinned;
    
end
%% spike binning
clearvars binstart binstarts binsize

binstarts = nan;
binsize = binsize_factor*sampling_rate;

for k = 1 : length(analysis)
    
    binstarts = 1:binsize:length(analysis(k).spikes);
    spikesbinned = nan;
    for bin = 1 : length(binstarts)-1
        spikesbinned(:,bin) = sum(analysis(k).spikes(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    analysis(k).spikesbinned = spikesbinned*(1/binsize_factor);
    
end

%% VM binning
clearvars binstart binstarts binsize

binstarts=nan;
binsize = binsize_factor*sampling_rate;

for k = 1 : length(analysis)
    
    binstarts = 1:binsize:length(analysis(k).VM);
    VMbinned=nan;
    for bin = 1 : length(binstarts)-1
        VMbinned(:,bin) = sum(analysis(k).VM(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    VMbinned = VMbinned/binsize;
    analysis(k).VMbinned = VMbinned;
    
end

%% Spike binning for trajcetory firing rate plot

dataset = analysis;
%dataset = analysis;

clearvars binstart binstarts binsize

binsize_factor_50Hz = 0.02;
%binsize_factor_50Hz = 0.1;      % 100 ms bins

binstarts = nan;
binsize = binsize_factor_50Hz*sampling_rate;

for k = 1 : length(dataset)
    
    binstarts = 1:binsize:length(dataset(k).spikes);
    spikesbinned_50Hz = nan;
    for bin = 1 : length(binstarts)-1
        spikesbinned_50Hz(:,bin) = sum(dataset(k).spikes(binstarts(bin):binstarts(bin+1)),'omitnan');
    end
    spikesnorm_binned = spikesbinned_50Hz/max(spikesbinned_50Hz);
    dataset(k).spikesnorm_binned = spikesnorm_binned';
    
end

%% Save analysis file
for i = 1 : length(analysis)
    analysis(i).duration_in_s = length(analysis(i).VM) / sampling_rate;
end

% save('post_walking_', 'analysis', '-v7.3');



%Remove recordings with VM < -25mV
analysis = analysis(~cellfun(@(x) x > -27,{analysis.medianVM}));

% analysis = analysis(~cellfun(@(x)x < 299,{analysis.duration_in_s}));

%Remove recordings with Spiek Amplitude < 6 mV
analysis = analysis(~cellfun(@(x)x < 6,{analysis.meanSpikeAmp}));


%% Plot overviews if necessary

%plot overviews of each cell with raw data of VM, binned spikerate and x
%velocity

plot_overviews = questdlg('Do you want to plot Overviews?','Check Overview?','Yes','No', 'No');

if strcmpi (plot_overviews, 'Yes')
    
    for k = 1 : length(analysis)
        
        x = (1:length(analysis(k).VM))/sampling_rate;
        xbin = (1:length(analysis(k).spikesbinned))/(sampling_rate/binsize);
        figure%('Name', 'Overview ' + analysis(k).ID)
        sp1 = subplot(4,1,1);
        plot(x,analysis(k).VM, 'k')
        sp2 = subplot(4,1,2);
        plot(xbin,analysis(k).xveloc_in_mm_binned, 'r')
        yline(0, 'k--')
        sp3 = subplot(4,1,3);
        plot(xbin,analysis(k).spikesbinned)
        sp4 = subplot(4,1,4);
        plot(x,analysis(k).VM_medfilt)
        linkaxes([sp1 sp2 sp3 sp4],'x')
        
        %xlim([temp_on_sec temp_off_sec])
        
    end
    
else
    
end

%% Cross correlation X vs Firing rate
clearvars spikesXveloc lags

figure
for k = 1 : length(analysis)

        [spikesXveloc(k,:), lags] = xcorr(zscore(analysis(k).spikesbinned),...
            zscore(analysis(k).xveloc_in_mm_binned), 8,'normalized');
        
        plot(lags/(1/binsize_factor), spikesXveloc(k,:), 'k')
        
        hold on
end

lagsInSec = lags/(1/binsize_factor);
meanxCorrSpikesXveloc = mean(spikesXveloc);
plot(lagsInSec ,meanxCorrSpikesXveloc, 'm', 'LineWidth', 3)
title(' mean spikerate-Xz score')
ylim([-0.6 0.6])

% print('-dpdf', '-painters', 'corsscorrelationX__zscore_with_mean.pdf');

% print(['corsscorrelationX_zscore_with_mean' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['corsscorrelationX_zscore_with_mean' '.png'], '-dpng','-r300')



figure
for k = 1 : length(analysis)

        [spikesXveloc(k,:), lags] = xcorr(zscore(analysis(k).spikesbinned),...
            zscore(analysis(k).xveloc_in_mm_binned), 8,'normalized');
        
        plot(lags/(1/binsize_factor), spikesXveloc(k,:), 'k')
        
        hold on
end

lagsInSec = lags/(1/binsize_factor);
meanxCorrSpikesXveloc = median(spikesXveloc);
plot(lagsInSec ,meanxCorrSpikesXveloc, 'm', 'LineWidth', 3)
title(' median spikerate-Xz score')
ylim([-0.6 0.6])
% print(['corsscorrelationX__zscore_with_median' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['corsscorrelationX__zscore_with_median' '.png'], '-dpng','-r300')
%% Cross correlation Z vs Firing rate
clearvars spikesZveloc lags right_cell left_cell plothandle

analysis = concat_analysis;

figure
for k = 1: length(analysis)

    if strcmp(analysis(k).Side, "right")
        color = 'k';
    else color = 'm';
    end
    [spikesZveloc(k,:), lags] = xcorr(zscore((analysis(k).spikesbinned)),...
        zscore((analysis(k).zveloc_in_mm_binned)), 8 ...
        , 'coeff');
    
    plothandle{k} = plot(lags/(1/binsize_factor), spikesZveloc(k,:), color);
    
    hold on

end

mean_right = [];
mean_left = [];

for i = 1 : length(analysis)
    if strcmp(analysis(i).Side, "right")
        mean_right(i,:) = spikesZveloc(i,:);
    else
        mean_left(i,:) = spikesZveloc(i,:);
    end
end

mean_left(all(mean_left == 0, 2), :) = [];
mean_right(all(mean_right == 0, 2), :) = [];

lagsInSec = lags/(1/binsize_factor);
meanxCorrSpikesZveloc = mean(spikesZveloc);
plot(lagsInSec ,median(mean_left), 'm', 'LineWidth', 3)
hold on
plot(lagsInSec ,median(mean_right), 'k', 'LineWidth', 3)

title('median  spikerate-Z zscore')
ylim([-0.4 0.4])
xlabel('Time (s)')
ylabel('Correlation coefficient')

legend('Left', 'Right')
%
% print(['corsscorrelationZ__zscore_with_median' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['corsscorrelationZ__zscore_with_median' '.png'], '-dpng','-r300')

clearvars spikesZveloc lags right_cell left_cell plothandle



clearvars spikesZveloc lags right_cell left_cell

figure
for k = 1 : length(analysis)

    [spikesZveloc(k,:), lags] = xcorr(zscore((analysis(k).spikesbinned)),...
        zscore(abs(analysis(k).zveloc_in_mm_binned)), 8 ...
        , 'coeff');
    
    plot(lags/(1/binsize_factor), spikesZveloc(k,:), 'k')
    
    hold on

end

lagsInSec = lags/(1/binsize_factor);
meanxCorrSpikesZveloc = median(spikesZveloc);

plot(lagsInSec ,meanxCorrSpikesZveloc, 'm', 'LineWidth', 3)
title('median  spikerate-abs(Z) zscore')
ylim([-0.3 0.6])

% print(['corsscorrelationZ__abs_zscore_with_median' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['corsscorrelationZ__abs_zscore_with_median' '.png'], '-dpng','-r300')

%% Pool spike frequency and velocites across all

clearvars temparray newArray binnedSpikesAll binnedXvelocAll binnedZvelocAll

analysis = analysis;

%Create cell arrays for spikes, x and z velocity
binnedSpikesAll = arrayfun(@(s) s.spikesbinned, analysis, 'UniformOutput', false);
binnedXvelocAll = arrayfun(@(s) s.xveloc_in_mm_binned, analysis, 'UniformOutput', false);
binnedZvelocAll = arrayfun(@(s) s.zveloc_in_degree_per_s_binned, analysis, 'UniformOutput', false);
binnedZvelocDegreeAll = arrayfun(@(s) s.zveloc_in_degree_per_s_binned, analysis, 'UniformOutput', false);


for k = 1 : length(analysis)

    %Put spikes and corresponding x velocity values in one array
    temparray(:,1) = binnedSpikesAll{k}(1,:);
    temparray(:,2) = binnedXvelocAll{k}(1,:);

    % Extract the unique spike frquencies from the first column
    uniqueFrequencies = unique(temparray(:, 1));

    % Initialize a cell array to store the results
    newArray = cell(length(uniqueFrequencies), 2);

    % Iterate over the unique spike frquencies and populate the new array
    for i = 1 : length(uniqueFrequencies)
        currentFrequency = uniqueFrequencies(i);

        % Find rows in the original array where the first column matches the current integer
        matchingRows = temparray(:, 1) == currentFrequency;

        % Extract the corresponding values from the second column
        correspondingVelocities = temparray(matchingRows, 2);

        % Store the current integer and the corresponding values in the new cell array
        newArray{i, 1} = currentFrequency;
        newArray{i, 2} = correspondingVelocities;

        SpikesPlusXvelocity{1,k} = newArray;


    end

    clearvars temparray newArray
end

figure
for i = 1 : length(analysis)

    for k = 1 : length(SpikesPlusXvelocity{i})

        plot_y = cell2mat(SpikesPlusXvelocity{1,i}(k,2));

        groups = cell2mat(SpikesPlusXvelocity{1,i}(k,1));

        boxplot2(plot_y, groups)

        hold on

    end
end

%% Pool data

clearvars spikesbinned_all xvelocbinned_all zvelocbinned_all_degree

analysis = analysis;

for k = 1 : length(analysis)
    temp_longest(:,k) = length(analysis(k).xveloc_in_mm_binned);
end

% xvelocbinned_all = nan(length(analysis),max(temp_longest)+1);
spikesbinned_all = nan(length(analysis),max(temp_longest)+1);
xvelocbinned_all_mm = nan(length(analysis),max(temp_longest)+1);
zvelocbinned_all_mm = nan(length(analysis),max(temp_longest)+1);
zvelocbinned_all_degree = nan(length(analysis),max(temp_longest)+1);



% for i = [1,2,7,8,12]
%     xvelocbinned_all(i,1:length(analysis(i).xvelocbinned)+1) = [analysis(i).xvelocbinned,0];
%     spikesbinned_all(i,1:length(analysis(i).spikesbinned)+1) = [0,analysis(i).spikesbinned];
% end
%

for k = 1 : length(analysis)

    % spikesbinned_all(k,1:length(analysis(k).spikesbinned)+1) = [0,analysis(k).spikesbinned];
    % xvelocbinned_all_mm(k,1:length(analysis(k).xveloc_in_mm_binned)+1) = ...
    %     [analysis(k).xveloc_in_mm_binned,0];
    % zvelocbinned_all_mm(k,1:length(analysis(k).zveloc_in_mm_binned)) = ...
    %     [analysis(k).zveloc_in_mm_binned];
    % zvelocbinned_all_degree(k,1:length(analysis(k).zveloc_in_degree_per_s_binned)) = ...
    %     [analysis(k).zveloc_in_degree_per_s_binned];
    spikesbinned_all(k,1:length(analysis(k).spikesbinned)) = [analysis(k).spikesbinned];
    xvelocbinned_all_mm(k,1:length(analysis(k).xveloc_in_mm_binned)) = ...
        [analysis(k).xveloc_in_mm_binned];
    zvelocbinned_all_mm(k,1:length(analysis(k).zveloc_in_mm_binned)) = ...
        [analysis(k).zveloc_in_mm_binned];
    zvelocbinned_all_degree(k,1:length(analysis(k).zveloc_in_degree_per_s_binned)) = ...
        [analysis(k).zveloc_in_degree_per_s_binned];
  

end

%Pool Z scored data
for k = 1 : length(analysis)

    spikesbinned_all_zscored(k,1:length((analysis(k).spikesbinned))+1) = [0,zscore(analysis(k).spikesbinned)];
    xvelocbinned_all_mm_zscored(k,1:length((analysis(k).xveloc_in_mm_binned))+1) = ...
        [zscore(analysis(k).xveloc_in_mm_binned),0];
    zvelocbinned_all_mm_zscored(k,1:length(zscore(analysis(k).zveloc_in_mm_binned))) = ...
        [zscore(analysis(k).zveloc_in_mm_binned)];

end
%% Plot pooled data



figure
boxplot(xvelocbinned_all_mm(:), spikesbinned_all(:), 'symbol', '','whisker', 0)
yline(0, 'k--')
% xlim([0 set_xlim_box-0.5])
ylim([-0.5 0.5])
title("Spike Frequencies per X Velocity")

figure
boxplot(abs(zvelocbinned_all_mm(:)), spikesbinned_all(:), 'symbol', '','whisker', 0)
yline(0, 'k--')
% xlim([0 set_xlim_box-0.5])
ylim([-0.5 0.5])
title("Spike Frequencies per Z Velocity")

figure
swarmchart(spikesbinned_all(:), xvelocbinned_all_mm(:), '.')
hold on
yline(0, 'k--')
%ylim([-1.2 1.2])
% xlim([-1 set_xlim_swarm-1])

figure
plot(spikesbinned_all(:), xvelocbinned_all_mm(:), '.')
hold on
yline(0, 'k--')
%ylim([-1.2 1.2])
%xlim([-1 set_xlim_swarm-1])

% print(['boxplots_frequencies' '.eps'], '-depsc2', '-tiff', '-r300', '-vector')
% print(['boxplots_frequencies' '.png'], '-dpng','-r300', '-vector')
%% Find all x velocity values for every spike frequency 

clearvars matchingValues indices plot_y_median freq_cutoff_temp 

freq_occurences = [];
unique_freq = [];

%look for spikerates and how often they occure
[freq_occurences, unique_freq] = groupcounts(spikesbinned_all(:));

%set limit for only plotting firing rates with more than 20 data points
freq_cutoff_temp = find(freq_occurences < 20);
freq_cutoff = freq_cutoff_temp(1)-1;
set_xlim_box = freq_cutoff;
set_xlim_swarm = unique_freq(freq_cutoff);

%Loop through all unique spike frequencies found in the whole dataset
for i = 1 : length(unique_freq(1:freq_cutoff))

    %Find each unique frecuency
    valueToFind = unique_freq(i);

    % Find indices in of frequency in the spikes array
    indices = find(spikesbinned_all == valueToFind);

    % Use logical indexing to extract the x velocity to the corresponding
    % spike frequency
    xVelocitySortedtoFreq{i} = xvelocbinned_all_mm(indices);

end

%Create a boxplot of spike frequency vs x velocity
figure
spike_frequencies = unique_freq(1:freq_cutoff);
counter_plotted = 0;
for i = 1 : length(unique_freq(1:freq_cutoff))

    plot_y = cell2mat(xVelocitySortedtoFreq(i));
    plot_y_median(i) = median(cell2mat(xVelocitySortedtoFreq(i)));
    groups = spike_frequencies(i);

    hbox{i} = boxplot2(plot_y, groups,'whisker', 0);
    %Add the number of datapoints per frequency to each box
    text(groups,1, ['n=' num2str(length(plot_y))])
    %Don't plot outliers
    set(hbox{i}.out, 'Marker', 'none')

    counter_plotted = counter_plotted +1;

end

%Normalize spike frequencies
spike_frequencies_norm = spike_frequencies/max(spike_frequencies);

%Create a boxplot of NORMALIZED spike frequency vs x velocity
figure
counter_plotted = 0;
for i = 1 : length(unique_freq(1:freq_cutoff))

    plot_y = cell2mat(xVelocitySortedtoFreq(i));
    %Calculate median x velocities for each frequency
    plot_y_median(i) = median(cell2mat(xVelocitySortedtoFreq(i)));
    groups = spike_frequencies_norm(i);

    hbox{i} = boxplot2(plot_y, groups,'whisker', 0);
    %Add the number of datapoints per frequency to each box
    % text(groups,1, ['n=' num2str(length(plot_y))])
    %Don't plot outliers

        set(hbox{i}.box, 'LineStyle', 'none')
        set(hbox{i}.out, 'Marker', 'none')
        set(hbox{i}.med, 'Linewidth', 1, 'Color', 'k')
        set(hbox{i}.med, 'LineStyle', 'none')
        set(hbox{i}.uadj, 'LineStyle', 'none')
        set(hbox{i}.ladj, 'LineStyle', 'none')

    counter_plotted = counter_plotted +1;

end

hold on
plot(spike_frequencies_norm', plot_y_median, '-', 'Linewidth', 3)
yline(0, 'k--')
ylim([-0.5 1.5])

%Calculate interquartile percentiles (25% and 75%)
for k = 1 : length(xVelocitySortedtoFreq) 
percentiles(:,k) = prctile(cell2mat(xVelocitySortedtoFreq(k)), [25 75], 'all');  
end

% Instead of error bars shade the area
% hold on
% xfill = spike_frequencies_norm';
% jbfill(xfill,percentiles(2,1:freq_cutoff), percentiles(1,1:freq_cutoff))

% Uncomment for error bars
hold on
for k = 1 : counter_plotted
    x = spike_frequencies_norm(k,:);
    y1 = percentiles(1,k);
    y2 = percentiles(2,k);
    plot([x x],[y1, y2], 'k-')  
end


percentiles_MDN = percentiles;

ylabel('Forward Velocity (mm/s)')
xlabel('norm. Firing Rate')
title('', 'Normalied Firing Rate vs Forward Velocity in mm/s')

print('-dpdf', '-painters', '_normalized_spike_rate_forward_velocity.pdf');

%% Find all Z velocity values for every spike frequency OVERALL

clearvars matchingValues indices plot_y_median plot_y zVelocitySortedtoFreq

%look for spikerates and how often they occure
[freq_occurences, unique_freq] = groupcounts(spikesbinned_all(:));

%set limit for only plotting firing rates with more than 20 data points
freq_cutoff_temp = find(freq_occurences < 20);
freq_cutoff = freq_cutoff_temp(1)-1;
set_xlim_box = freq_cutoff;
set_xlim_swarm = unique_freq(freq_cutoff);

%Invert right to left turns
zvelocbinned_all_degree = abs(zvelocbinned_all_degree);

%Loop through all unique spike frequencies found in the whole dataset
for i = 1 : length(unique_freq(1:freq_cutoff))
    %Find each unique frecuency
    valueToFind = unique_freq(i);
    % Find indices in of frequency in the spikes array
    indices = find(spikesbinned_all == valueToFind);
    % Use logical indexing to extract the x velocity to the corresponding
    % spike frequency
    zVelocitySortedtoFreq{i} = zvelocbinned_all_degree(indices);    
end

%Create a boxplot of spike frequency vs Z velocity
figure
spike_frequencies = unique_freq(1:freq_cutoff);
counter_plotted = 0;
for i = 1 : length(unique_freq(1:freq_cutoff))

    plot_y = cell2mat(zVelocitySortedtoFreq(i));
    plot_y_median(i) = median(cell2mat(zVelocitySortedtoFreq(i)));
    groups = spike_frequencies(i);

    hbox{i} = boxplot2(plot_y, groups,'whisker', 0);
    %Add the number of datapoints per frequency to each box
    text(groups,1, ['n=' num2str(length(plot_y))])
    %Don't plot outliers
    set(hbox{i}.out, 'Marker', 'none')

    counter_plotted = counter_plotted +1;

end

%Normalize spike frequencies
spike_frequencies_norm = spike_frequencies/max(spike_frequencies);

%Create a boxplot of NORMALIZED spike frequency vs Z velocity
figure
counter_plotted = 0;
for i = 1 : length(unique_freq(1:freq_cutoff))

    plot_y = cell2mat(zVelocitySortedtoFreq(i));
    %Calculate median x velocities for each frequency
    plot_y_median(i) = median(cell2mat(zVelocitySortedtoFreq(i)));
    groups = spike_frequencies_norm(i);

    hbox{i} = boxplot2(plot_y, groups,'whisker', 0);
    %Add the number of datapoints per frequency to each box
    % text(groups,1, ['n=' num2str(length(plot_y))])
    %Don't plot outliers

        set(hbox{i}.box, 'LineStyle', 'none')
        set(hbox{i}.out, 'Marker', 'none')
        set(hbox{i}.med, 'Linewidth', 1, 'Color', 'k')
        set(hbox{i}.med, 'LineStyle', 'none')
        set(hbox{i}.uadj, 'LineStyle', 'none')
        set(hbox{i}.ladj, 'LineStyle', 'none')

    counter_plotted = counter_plotted +1;

end

hold on
plot(spike_frequencies_norm', plot_y_median, '-', 'Linewidth', 3)
yline(0, 'k--')
ylim([0 100])
%Calculate interquartile percentiles (25% and 75%)
percentiles = [];
for k = 1 : length(zVelocitySortedtoFreq) 
percentiles(:,k) = prctile(cell2mat(zVelocitySortedtoFreq(k)), [25 75], 'all');  
end
%Plot percentiles 
for k = 1 : counter_plotted
    x = spike_frequencies_norm(k,:);
    y1 = percentiles(1,k);
    y2 = percentiles(2,k);
    plot([x x],[y1, y2], 'k-')  
end
ylabel('Angular Velocity (°/s)')
xlabel('norm. Firing Rate')
title('', 'Normalied Firing Rate vs Z Velocity in °/s')

% print(['_normalized_spike_rate_angular_velocity' '.eps'], '-depsc2', '-tiff', '-r300', '-vector')
% print(['_normalized_spike_rate_angular_velocity' '.png'], '-dpng','-r300', '-vector')
% print('-dpdf', '-painters', '_normalized_spike_rate_angular_velocity.pdf');


%% Moving cross correlation --------- Z Velocity
clearvars coeff lags mean_coeff coeff_temp data_vm data_xvelo mean_per_cell_coeff

%Size of the window for moving cross correlation in second
moving_window = 2*sampling_rate;
moving_window_in_s = moving_window/sampling_rate;

figure
for n = 1 : length(analysis)

    saveStartIndex = [];
    saveStopIndex = [];

    k = 1;

    %Data for cross correlation
    data_vm = analysis(n).VM_medfilt;
    data_xvelo = (analysis(n).zveloc_in_degree_per_s);
    data_length_in_s = (length(data_vm)/sampling_rate);

    %Number of windows for cross correlatons
    num_windows = floor(data_length_in_s/moving_window_in_s);

    %Preallocate array for saving cross correlation coefficients
    coeff = NaN(num_windows, (moving_window*2)+1)';

    for startIndex = 1 : moving_window : length(data_vm)

        stopIndex = startIndex + moving_window;
        if stopIndex > length(data_vm)
            stopIndex = length(data_vm);
        else
        end
       
        %Save start and stop indices for later debugging
        saveStartIndex(k) = startIndex;
        saveStopIndex(k) = stopIndex;       

        if startIndex == 1
            %For the first window no overlap between windows is needed
             [coeff(:,k), lags] = xcorr(zscore(data_vm(startIndex:stopIndex)),...
                zscore(data_xvelo(startIndex:stopIndex)), 'coeff');

        else          
             [coeff_temp, lags] = xcorr(zscore(data_vm(startIndex-sampling_rate:stopIndex-sampling_rate)),...
                 zscore(data_xvelo(startIndex-sampling_rate:stopIndex-sampling_rate)), 'coeff');

             coeff_temp(end:length(coeff),:) = missing;

             coeff(:,k) = coeff_temp;
        end

        k = k + 1;

    end

        lags = -moving_window : +moving_window;
        mean_per_cell_coeff(:,n) = mean(coeff,2, 'omitnan');
        % % 
        plothandle{n} = plot(lags/sampling_rate, mean_per_cell_coeff(:,n), 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
        hold on
        coeff = [];
        xlim([-2 2])
end

lags = -moving_window : +moving_window;

mean_overall_coeff = median(mean_per_cell_coeff,2);
% plot(lags/sampling_rate, mean_overall_coeff, 'k', 'LineWidth', 3)
xlim([-2 2])
title("", "Cross correlation of meanVM vs Z Velocity")
xlabel("Lag (s)")
ylabel("Correlation coefficient")
[Value, Idx ] = max(mean_overall_coeff);
maxCoeff = lags(Idx)/sampling_rate;
% text(-1.5, 0.25, ['max coeff at = ' num2str(maxCoeff) ' s'])

temp_mean_coeff_right = [];
temp_mean_coeff_left = [];

%Labeling of actual side of recording
for i = 1 : n
    if analysis(i).Side == "right"       
        plothandle{i}.Color = 'b';
        temp_mean_coeff_right = [temp_mean_coeff_right  mean_per_cell_coeff(:,i)];
    elseif analysis(i).Side == "left"  
        plothandle{i}.Color = 'm';
        temp_mean_coeff_left = [temp_mean_coeff_left  mean_per_cell_coeff(:,i)];
    end
end

mean_coeff_right = mean(temp_mean_coeff_right,2);
mean_coeff_left = mean(temp_mean_coeff_left,2);

plot(lags/sampling_rate, mean_coeff_right, 'k', 'LineWidth', 3)
hold on
plot(lags/sampling_rate, mean_coeff_left, 'k', 'LineWidth', 3)

% legend([plothandle{1} plothandle{8} plothandle{9}], 'Left', 'Right', 'Undefined')
% 

% print('-dpdf', '-painters', 'crosscorr__VM_Z.pdf');

print(['2s_window_mean_crosscorr__VM_Z' '.eps'], '-depsc2', '-tiff', '-r300')
print(['2s_window_mean_crosscorr__VM_Z' '.png'], '-dpng','-r300')

%% Moving cross correlation --------- absolute Z Velocity
clearvars coeff lags mean_coeff coeff_temp data_vm data_xvelo mean_per_cell_coeff

%Size of the window for moving cross correlation in second
moving_window = 10*sampling_rate;
moving_window_in_s = moving_window/sampling_rate;

figure
for n = 1 : length(analysis)

    saveStartIndex = [];
    saveStopIndex = [];

    k = 1;

    %Data for cross correlation
    data_vm = analysis(n).VM_medfilt;
    data_xvelo = abs(analysis(n).zveloc_in_degree_per_s);
    data_length_in_s = (length(data_vm)/sampling_rate);

    %Number of windows for cross correlatons
    num_windows = floor(data_length_in_s/moving_window_in_s);

    %Preallocate array for saving cross correlation coefficients
    coeff = NaN(num_windows, (moving_window*2)+1)';

    for startIndex = 1 : moving_window : length(data_vm)

        stopIndex = startIndex + moving_window;
        if stopIndex > length(data_vm)
            stopIndex = length(data_vm);
        else
        end
       
        %Save start and stop indices for later debugging
        saveStartIndex(k) = startIndex;
        saveStopIndex(k) = stopIndex;       

        if startIndex == 1
            %For the first window no overlap between windows is needed
             [coeff(:,k), lags] = xcorr(zscore(data_vm(startIndex:stopIndex)),...
                zscore(data_xvelo(startIndex:stopIndex)), 'coeff');

        else          
             [coeff_temp, lags] = xcorr(zscore(data_vm(startIndex-sampling_rate:stopIndex-sampling_rate)),...
                 zscore(data_xvelo(startIndex-sampling_rate:stopIndex-sampling_rate)), 'coeff');

             coeff_temp(end:length(coeff),:) = missing;

             coeff(:,k) = coeff_temp;
        end

        k = k + 1;

    end

        lags = -moving_window : +moving_window;
        mean_per_cell_coeff(:,n) = median(coeff,2, 'omitnan');
        % % 
        plothandle{n} = plot(lags/sampling_rate, mean_per_cell_coeff(:,n), 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
        hold on
        coeff = [];
end

lags = -moving_window : +moving_window;

mean_overall_coeff = median(mean_per_cell_coeff,2);
plot(lags/sampling_rate, mean_overall_coeff, 'k', 'LineWidth', 3)
xlim([-2 2])
ylim([-0.3 0.5])
title("", "Cross correlation of medianVM vs abs Z Velocity")
xlabel("Lag (s)")
ylabel("Correlation coefficient")
[Value, Idx ] = max(mean_overall_coeff);
maxCoeff = lags(Idx)/sampling_rate;
% text(-1.5, 0.25, ['max coeff at = ' num2str(maxCoeff) ' s'])

% print('-dpdf', '-painters', 'crosscorr__VM_absZ.pdf');

% print(['median_crosscorr__VM_absZ' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['median_crosscorr__VM_absZ' '.png'], '-dpng','-r300')

%% Moving cross correlation --------- X Velocity
clearvars coeff lags mean_coeff coeff_temp data_vm data_xvelo mean_per_cell_coeff

%Size of the window for moving cross correlation in second
moving_window = 10*sampling_rate;
moving_window_in_s = moving_window/sampling_rate;

figure
for n = 1 : length(analysis)

    saveStartIndex = [];
    saveStopIndex = [];

    k = 1;

    %Data for cross correlation
    data_vm = analysis(n).VM_medfilt;
    data_xvelo = (analysis(n).xveloc_in_mm);
    data_length_in_s = (length(data_vm)/sampling_rate);

    %Number of windows for cross correlatons
    num_windows = floor(data_length_in_s/moving_window_in_s);

    %Preallocate array for saving cross correlation coefficients
    coeff = NaN(num_windows, (moving_window*2)+1)';

    for startIndex = 1 : moving_window : length(data_vm)

        stopIndex = startIndex + moving_window;
        if stopIndex > length(data_vm)
            stopIndex = length(data_vm);
        else
        end
       
        %Save start and stop indices for later debugging
        saveStartIndex(k) = startIndex;
        saveStopIndex(k) = stopIndex;       

        if startIndex == 1
            %For the first window no overlap between windows is needed
             [coeff(:,k), lags] = xcorr(zscore(data_vm(startIndex:stopIndex)),...
                zscore(data_xvelo(startIndex:stopIndex)), 'coeff');

        else          
             [coeff_temp, lags] = xcorr(zscore(data_vm(startIndex-sampling_rate:stopIndex-sampling_rate)),...
                 zscore(data_xvelo(startIndex-sampling_rate:stopIndex-sampling_rate)), 'coeff');

             coeff_temp(end:length(coeff),:) = missing;

             coeff(:,k) = coeff_temp;
        end

        k = k + 1;

    end

        lags = -moving_window : +moving_window;
        mean_per_cell_coeff(:,n) = mean(coeff,2, 'omitnan');
        % % 
        plothandle{n} = plot(lags/sampling_rate, mean_per_cell_coeff(:,n), 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
        hold on
        coeff = [];
end

lags = -moving_window : +moving_window;

mean_overall_coeff = median(mean_per_cell_coeff,2);
plot(lags/sampling_rate, mean_overall_coeff, 'k', 'LineWidth', 3)
xlim([-2 2])
ylim([-0.2 0.2])
title("", "Cross correlation of medianVM vs X Velocity")
xlabel("Lag (s)")
ylabel("Correlation coefficient")
[Value, Idx ] = max(mean_overall_coeff);
maxCoeff = lags(Idx)/sampling_rate;
% text(-1.5, 0.25, ['max coeff at = ' num2str(maxCoeff) ' s'])

% print('-dpdf', '-painters', 'crosscorr__VM_X.pdf');
% print(['median_crosscorr__VM_X' '.eps'], '-depsc2', '-tiff', '-r300')
% print(['median_crosscorr__VM_X' '.png'], '-dpng','-r300')