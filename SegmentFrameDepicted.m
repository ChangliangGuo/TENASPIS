function [cc,PeakPix,NumItsTaken,threshlist] = SegmentFrameDepicted(frame,mask,thresh)
% [frame,cc,ccprops] = SegmentFrame(frame,mask,thresh)
%
%   Identifies local maxima and separates them out into neuron sized blobs.
%   Does so in an adaptive manner by iteratively bumping up the threshold
%   until no new blobs are identified.
%
%   INPUTS:
%
%       frame: a frame from an braing imaging movie
%
%       mask: a logical array the same size as frame indicating which areas
%       have valid neurons (ones) and which do not (zeros)
%
%       thresh: the starting value at which you will threshold the values in
%       frame to being looking for blobs
%
%   OUTPUTS:
%
%       cc: structure variable containing all the relevant data/statistics 
%       about the blobs discovered (e.g. the pixel indices for each blob) 
%
%       PeakPix: a cell array with the x/y pixel indices for the location 
%       of the peak pixel intensity for each blob.
%
%       NumItsTaken: number of iterations taken to identify each blob.
%
% Copyright 2015 by David Sullivan and Nathaniel Kinsky
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of Tenaspis.
%
%     Tenaspis is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     Tenaspis is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with Tenaspis.  If not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

currdir = pwd;

aviobj = VideoWriter('blobdemo','MPEG-4');
aviobj.FrameRate = 4;
aviobj.Quality = 100;
open(aviobj);

% Parameters
minpixels = 150; %60 minimum blob size during initial segmentation
adjminpixels = 150; %40 minimum blob size during re-segmentation attempts
threshinc = 0.001; % how much to increase threshold by on each re-segmentation iteration
neuronthresh = 300; %160 maximum blob size to be considered a neuron
minsolid = 0.9; % minimum blob solidity to be considered a neuron
axisRatioMax = 2;
% Setup variables for below
PeakPix = []; % Locations of peak pixels 
threshlist = [];
badpix = find(mask == 0); % Locations of pixels that are outside the mask and should be excluded

% threshold and segment the frame
initframe = single(frame);


% Figure 1: Raw Frame !!!!!!!!!!!!!!!!!!!!!!!
FigCount = 1;
figure(1);
imagesc(initframe);
caxis([0 max(initframe(:))]);
colorbar;
title('raw frame');
axis image;
set(gcf,'Position',[181          68        1059         910]);
F = getframe(gcf);
% write to avi
writeVideo(aviobj,F);
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

blankframe = zeros(size(initframe));
minval = min(initframe(:));
threshframe = frame > thresh; % apply threshold, make it into a logical array

% Figure 2: Thresholded frame!!!!!!!!!!!!!!!!
FigCount = FigCount+1;
figure(1);
imagesc(threshframe);
caxis([0 1]);
colorbar;
title('threshold frame');
axis image;
set(gcf,'Position',[181          68        1059         910]);
F = getframe(gcf);
% write to avi
writeVideo(aviobj,F);

% Figure 3: 
threshframe = bwareaopen(threshframe,minpixels,4); % remove blobs smaller than minpixels
FigCount = FigCount+1;
figure(1);
imagesc(threshframe);
caxis([0 1]);
colorbar;
title(['removed blobs < ',int2str(minpixels),' pixels']);
axis image;
set(gcf,'Position',[181          68        1059         910]);
F = getframe(gcf);
% write to avi
writeVideo(aviobj,F);


% Set up variables for while loop below
newlist = [];
currnewList = 0;
BlobsInFrame = 1;
NumIts = 0;
tNumItsTaken = [];

while BlobsInFrame
    NumIts = NumIts + 1;
    BlobsInFrame = 0; % reset each loop
    % threshold and segment the frame
    
    bb = bwconncomp(threshframe,4); % Look for connected regions/blobs in threshframe
    rp = regionprops(bb,'Area','Solidity','MajorAxisLength','MinorAxisLength'); % Pull area and solidity properties
    
    % Break while loop if no blobs meeting all the criteria are found
    if (isempty(bb.PixelIdxList))
        break;
    end
    
    FigCount = FigCount+1;
    figure(1);
    displayframe = initframe;
    displayframe(find(initframe < thresh)) = 0;
    imagesc(displayframe);
    caxis([0 max(initframe(:))]);
    colorbar;
    title(['all blobs']);
    axis image;
    hold on;
    set(gcf,'Position',[181          68        1059         910]);
    % plot all neuron outlines
    for i = 1:length(bb.PixelIdxList)
        temp = zeros(size(initframe));
        temp(bb.PixelIdxList{i}) = 1;
        btemp = bwboundaries(temp,4);
        plot(btemp{1}(:,2),btemp{1}(:,1),'-r','LineWidth',3)
    end
    set(gcf,'Position',[181          68        1059         910]);
    hold off;

    
    % if there were blobs, check if any of them satisfy size and
    % solidity criteria
    bsize = deal([rp.Area]);
    bSolid = deal([rp.Solidity]);
    bMaj = deal([rp.MajorAxisLength]);
    bMin = deal([rp.MinorAxisLength]);
    bRat = bMaj./bMin;
    
    % Look for new blobs that meet the maximum size AND minimum solidity criteria
    newn = intersect(find(bsize <= neuronthresh), find(bSolid >= minsolid));
    newn = intersect(newn,find(bRat < axisRatioMax));
    
    hold on;
    
    % plot old ROIs
    for j = 1:currnewList
        temp = zeros(size(initframe));
        temp(newlist{j}) = 1;
        btemp = bwboundaries(temp,4);
        plot(btemp{1}(:,2),btemp{1}(:,1),'-k','LineWidth',3)   
    end
    
    for j = 1:length(newn)
        % append new blob pixel lists
        currnewList = currnewList + 1;
        newlist{currnewList} = bb.PixelIdxList{newn(j)};
        threshlist(currnewList) = thresh;
        tNumItsTaken(currnewList) = NumIts;
        
        temp = zeros(size(initframe));
        temp(bb.PixelIdxList{newn(j)}) = 1;
        btemp = bwboundaries(temp,4);
        plot(btemp{1}(:,2),btemp{1}(:,1),'-g','LineWidth',3)
    end
       
    % If nothing is left to split, break out of the while loop
    if (length(newn) == length(bb.PixelIdxList))
        break;
    end
    
    FigCount = FigCount+1;
    set(gcf,'Position',[181          68        1059         910]);
    hold off;
    title(int2str(NumIts));
    F = getframe(gcf);
    % write to avi
    writeVideo(aviobj,F);
    % If there are still blobs left
    BlobsInFrame = 1;
    % Define old blobs as those that do NOT meet either the size OR solidity
    % criteria.
    oldn = union(find(bsize > neuronthresh), find(bSolid<minsolid));
    
    % make a frame containing the remaining blobs
    temp = blankframe + minval;
    for j = 1:length(oldn)
        temp(bb.PixelIdxList{oldn(j)}) = initframe(bb.PixelIdxList{oldn(j)});
    end
    
    % increase threshold
    thresh = thresh + threshinc;
    threshframe = temp > thresh;
    
    % remove areas with less than adjminpixels
    threshframe = bwareaopen(threshframe,adjminpixels,4); 
    
    % Run throuh while loop again to determine if new threshold has
    % produced any more legitimate blobs.
    
end

imagesc(initframe)
    for j = 1:currnewList
        temp = zeros(size(initframe));
        temp(newlist{j}) = 1;
        btemp = bwboundaries(temp,4);
        plot(btemp{1}(:,2),btemp{1}(:,1),'-k','LineWidth',3)   
    end
F = getframe(gcf);
% write to avi
writeVideo(aviobj,F);    
NumItsTaken = []; % Initialize Number of iterations to empty

% exit if no blobs found
if (isempty(newlist))
    PeakPix = [];
    threshlist = [];
    cc.NumObjects = 0;
    cc.PixelIdxList = [];
    cc.PixelVals = [];
    cc.ImageSize = size(frame);
    cc.Connectivity = 0; 
    %display('no blobs detected');
    return;
end

% Initialize variables
numlists = 0;
newcc.PixelIdxList = [];

% Step through each new blob in the frame 
for i = 1:length(newlist)
    % Check to make sure blobs are within the neuron mask
    if (isempty(intersect(newlist{i},badpix)))
        numlists = numlists + 1; % Count of number of blobs
        newcc.PixelIdxList{numlists} = single(newlist{i}); % Pixel indices for blob
        newcc.PixelVals{numlists} = single(initframe(newlist{i}));
        NumItsTaken(numlists) = tNumItsTaken(i); % Save iterations required to ID each blob
    end
end

% Dump everything into newcc variable
newcc.NumObjects = numlists;
newcc.ImageSize = size(frame);
newcc.Connectivity = 4;
cc = newcc;

% get peak pixel
PeakPix = cell(1,length(cc.PixelIdxList)); 
for i = 1:length(cc.PixelIdxList)
    [~,idx] = max(initframe(cc.PixelIdxList{i}));
    [PeakPix{i}(1),PeakPix{i}(2)] = ind2sub(cc.ImageSize,cc.PixelIdxList{i}(idx));
end

end