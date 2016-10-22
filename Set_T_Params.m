function [] = Set_T_Params(moviefile);
% function [] = Set_T_Params(moviefile);
%
% Sets Tenaspis parameters.  Must be called at beginning of run
%
% Copyright 2016 by David Sullivan, Nathaniel Kinsky, and William Mau
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

clear T_PARAMS;
global T_PARAMS;

%% The dimensions of the movie - load from .mat file if possible, to save time when this function is called by parfor workers
if (~exist('MovieDims.mat','file'))
    info = h5info(moviefile,'/Object');
    [T_PARAMS.Xdim,Xdim] = deal(info.Dataspace.Size(1));
    [T_PARAMS.Ydim,Ydim] = deal(info.Dataspace.Size(2));
    [T_PARAMS.NumFrames,NumFrames] = deal(info.Dataspace.Size(3));
    save MovieDims.mat Xdim Ydim NumFrames
else
    load('MovieDims.mat','Xdim','Ydim','NumFrames');
    T_PARAMS.Xdim = Xdim;
    T_PARAMS.Ydim = Ydim;
    T_PARAMS.NumFrames = NumFrames;
end

%% General parameters used by multiple scripts
T_PARAMS.FrameChunkSize = 1250; % Number of frames to load at once for various functions

%% MakeFilteredMovies
T_PARAMS.HighPassRadius = 20; % Smoothing radius for high pass filtering
T_PARAMS.LowPassRadius = 3; % Smoothing radius for low pass filtering

%% ExtractBlobs / SegmentFrame params
T_PARAMS.threshold = 0.01; % Pixel intensity baseline threshold for detecting blobs
T_PARAMS.threshsteps = 10; % number of threshold increments to try in order to find criterion region within non-criterion blob and check for multiple peaks in criterion blobs
T_PARAMS.MaxBlobRadius = 15; % Maximum radius for a circular shaped blob to be included
T_PARAMS.MinBlobRadius = 5; % Minimum radius for circular shaped blob to be included
T_PARAMS.MaxAxisRatio = 2; % Maximum ratio of major to minor axis length for blobs. Keeps overly slivery blobs and some juxtaposition artifacts out of the data
T_PARAMS.MinSolidity = 0.95; % Minimum blob 'solidity', which is the ratio of the perimeter of the convex hull to the actual perimeter. Prevents jagged and strange shaped blobs





end

