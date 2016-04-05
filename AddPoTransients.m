function AddPoTransients()
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

%% Parameters
buddy_dist_thresh = 15; % Any neurons with a centroid less than this many pixels away are considered a buddy
rankthresh = 0.55; % DAVE - what is this / how did you come up with this?

%%
disp('Loading relevant variables')
load pPeak.mat;
load ExpTransients.mat;
load('ProcOut.mat','NumNeurons','NumFrames','NeuronPixels','NeuronImage','Xdim','Ydim');

expPosTr = PosTr; % Expanded positive transients - this gets updated below, while PosTr does not

% Get centroids
Cents = zeros(length(NeuronImage),2); % Initialize
for i = 1:length(NeuronImage)
    b = bwconncomp(NeuronImage{i});
    r = regionprops(b,'Centroid');
    Cents(i,1:2) = r.Centroid;
end

temp = pdist(Cents);
CentDist = squareform(temp);

info = h5info('SLPDF.h5','/Object'); % Get movie info for loadframe below

%display('checking buddies');

% Identify buddy neurons for each neuron
for j = 1:NumNeurons
    buddies{j} = [];
    for i = 1:NumNeurons
        
        % Don't count neuron itself as a buddy
        if (i == j) 
            continue;
        end
        
        % Save buddy if it is less than the buddy distance threshold away
        if (CentDist(i,j) <= buddy_dist_thresh)
            buddies{j} = [buddies{j},i];
        end
        
    end
end

keyboard

%% Nat attempt to load all information on max pixel index for each neuron
% ahead of time to speed up below

profile off
profile on

maxidx_full = nan(NumNeurons,NumFrames);
meanpix_full = nan(NumNeurons,NumFrames);
% Initialize ProgressBar
resol = 5; % Percent resolution for progress bar, in this case 10%
p = ProgressBar(100/resol);
update_inc = round(NumFrames/(100/resol)); % Get increments for updating ProgressBar
for i = 1:NumFrames
            
    f = loadframe('SLPDF.h5', i, info); % Load frame i
    
    % Get max pixel index and mean pixel intensity for each neuron
    for j = 1:NumNeurons
        [~,maxidx_full(j,i)] = max(f(NeuronPixels{j}));
        meanpix_full(j,i) = mean(f(NeuronPixels{j}));
    end
    
    if round(i/update_inc) == (i/update_inc)
        p.progress; % Also percent = p.progress;
    end
    
end
p.stop;

profile viewer
%%

profile off
profile on

disp('Adding potential transients...');
p = ProgressBar(NumNeurons);
for i = 1:NumNeurons
    %display(['Neuron ',int2str(i)]);

    % Identify potential epochs where there may be a spike for neuron i
    PoEpochs = NP_FindSupraThresholdEpochs(PoPosTr(i,:),eps); 
    
    % Loop through each epoch and check for buddy spiking - if there is
    % none, add a new transient!
    for j = 1:size(PoEpochs,1)
        
        % initialize variables
        buddyspike = 0; % binary for if there is a buddy spike
        buddyconfs = []; % 
        
        % Loop through each buddy neuron and identify if there was a buddy
        % spike or if there is a potential positive transient
        for k = 1:length(buddies{i})
            
            % Identify buddy spikes from expanded positive transients
            % (confirmed spikes)
            if sum(expPosTr(buddies{i}(k),PoEpochs(j,1):PoEpochs(j,2))) > 0
                buddyspike = 1; % If so, set binary to 1 to initiate checking below
            end
            
            % Identify if there was activity in the original transient
            % variable for buddy neurons (potential buddy conflicts)
            if (sum(PoPosTr(buddies{i}(k),PoEpochs(j,1):PoEpochs(j,2))) > 0)
                buddyconfs = [buddyconfs,buddies{i}(k)]; % accrue list of buddies with potential spiking activity in original (unexpanded) transients       
            end
        end
        
        % Skip to next epoch without adding a transient if there is a buddy
        % spike
        if buddyspike
            %display('buddy spike');
            continue;
        end
        
        %%% If there is not a buddy spike, check the peak %%%
        maxidx = [];

        ps = PoTrPeakIdx{i}(j)-10; % Grab the 10 frames active before the time of neuron i's potential spike in epoch j
        
        % Identify the pixel index for the max pixel intensity in neuron i for each of these frames
        for k = ps:PoTrPeakIdx{i}(j)
            
%             f = loadframe('SLPDF.h5', k, info); NRK commenting to test
%             out speed increases
%             [~,maxidx(k)] = max(f(NeuronPixels{i}));
            maxidx(k) = maxidx_full(i,k); 
            
        end
        
        % If there are potential buddy conflicts, get the mean pixel
        % intensity for each buddy neuron during the peak of the potential
        % spike of neuron i in epoch j
        meanpix = [];
        if ~isempty(buddyconfs)
            %display('buddy conflict');
            
            % Accrue list of means
            for k = 1:length(buddyconfs)
%                 meanpix(k) = mean(f(NeuronPixels{buddyconfs(k)})); % NRK commenting to test out speed increases % DAVE - this is only looking at the frame at the of PoTrPeakIds{i}(j) - is that correct?
                meanpix(k) = meanpix_full(buddyconfs(k),PoTrPeakIdx{i}(j)); % mean of buddy k at time of potential peak transient
            end
            
            % Now, compare.  If the mean of neuron i pixels at its peak in
            % epoch j is less than the maximum of the mean of all the
            % buddy neurons, then buddy activity probably caused the
            % potential transient so don't add a new one
            if (mean(f(NeuronPixels{i})) < max(meanpix))
                %display('lost conflict');
                continue;
            end
        end
        
        % Get the subs for the location of the maximum pixel intensity in
        % neuron i during the ten frames preceding the peak in epoch j
        [xp,yp] = ind2sub([Xdim,Ydim],maxidx(end-10:end));
        
        % identify the index corresponding to the average of the above
        meanmaxidx = sub2ind([Xdim,Ydim],round(median(xp)),median(mean(yp)));
        peakpeak = pPeak{i}(meanmaxidx); % Get the peak value?
        peakrank = mRank{i}(meanmaxidx); % Get the rank of the peak pixel?
        
        % NAT - continue here after you figure out what Calc_pPeak does...
        if (peakpeak > 0) && (peakrank > rankthresh)
            %display('new transient!');
            expPosTr(i,PoEpochs(j,1):PoEpochs(j,2)) = 1;
        else
            %display('pixels off kilter');
            if peakpeak == 0
                %display('this pixel is never the peak');
            end
            if peakrank < rankthresh
                %display('mean rank of the peak not high enough');
            end
        end
        
    end
    
    p.progress;
end
p.stop; 

profile viewer

%%
save expPosTr.mat expPosTr;

end