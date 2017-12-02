function [BlobPixelIdxList,BlobWeightedCentroids,BlobMinorAxisLength] = NewSegmentFrame(frame,PrepMask,CheckPeaks,ThreshOverride)


[Xdim,Ydim,threshold,threshsteps,MaxBlobRadius,MinBlobRadius,MaxAxisRatio,MinSolidity] = ...
    Get_T_Params('Xdim','Ydim','threshold','threshsteps','MaxBlobRadius','MinBlobRadius','MaxAxisRatio','MinSolidity');

if (~exist('PrepMask','var'))
    PrepMask = true(Xdim,Ydim);
else
    if (isempty(PrepMask))
        PrepMask = true(Xdim,Ydim);
    end
end
ToPlot = false;
% Derived Parameters
MaxBlobArea = ceil((MaxBlobRadius^2)*pi);
MinBlobArea = ceil((MinBlobRadius^2)*pi);

%% Setup variables for below
badpix = find(PrepMask == 0); % Locations of pixels that are outside the mask and should be excluded
blankframe = zeros(Xdim,Ydim,'single');

maxframe = max(frame(PrepMask));

%threshinc = (maxframe-threshold)/threshsteps,
threshinc = 0.001;

threshlist = threshold:threshinc:maxframe*.95;

CurrGoodBlob = 0;
BlobPixelIdxList = [];

for i = 1:length(threshlist)
    threshframe = frame > threshlist(i);
    threshframe = bwareaopen(threshframe,MinBlobArea,4); % remove blobs smaller than minpixels
    rp = regionprops(bwconncomp(threshframe,4),'Area','Solidity','MajorAxisLength','MinorAxisLength','PixelIdxList','Centroid');
    NumHits = zeros(1,length(BlobPixelIdxList));
    OldNumBlobs = length(BlobPixelIdxList);
    
    for j = 1:length(rp)
        % check basic properties
        AxisRatio = rp(j).MajorAxisLength/rp(j).MinorAxisLength;
        
        CriteriaOK = (rp(j).Solidity > MinSolidity) && (AxisRatio < MaxAxisRatio) && (rp(j).Area < MaxBlobArea) && (rp(j).MajorAxisLength < 2*MaxBlobRadius);
        if(~CriteriaOK)
            continue;
        end
        
        
        % ok so it looks good but do we already have it?
        AlreadyFound = false;
        BetterThanBefore = false;
        CentroidIdx = sub2ind([Xdim Ydim],ceil(rp(j).Centroid(2)),ceil(rp(j).Centroid(1)));
        
        for k = 1:OldNumBlobs
            if(ismember(CentroidIdx,BlobPixelIdxList{k}))
                AlreadyFound = true;
                NumHits(k) = NumHits(k) + 1;
                BetterThanBefore = ((rp(j).Solidity > BlobSolidity(k)) && (AxisRatio < BlobAxisRatio(k)));
                if(BetterThanBefore)
                    % this guarantees that the matching blob gets deleted
                    NumHits(k) = NumHits(k)+1;
                    %disp('kept blob at a higher threshold');
                end
                break;
            end
        end
        
        if(AlreadyFound && ~BetterThanBefore)
            continue;
        end
        
        % ok at this point it's a new blob
        CurrGoodBlob = CurrGoodBlob + 1;
        BlobPixelIdxList{CurrGoodBlob} = rp(j).PixelIdxList;
        BlobWeightedCentroids{CurrGoodBlob} = single(rp(j).Centroid);
        BlobMinorAxisLength(CurrGoodBlob) = single(rp(j).MinorAxisLength);
        BlobAxisRatio(CurrGoodBlob) = AxisRatio;
        BlobSolidity(CurrGoodBlob) = single(rp(j).Solidity);
    end
    
    BadGuys = find(NumHits > 1);
    for j = 1:length(BadGuys)
        BlobPixelIdxList{BadGuys(j)} = [];
    end
end

GoodBlob = ones(1,CurrGoodBlob);
for i = 1:CurrGoodBlob
    if(isempty(BlobPixelIdxList{i}) || (~isempty(intersect(BlobPixelIdxList{i},badpix))))
        GoodBlob(i) = 0;
    end
end
BlobPixelIdxList = BlobPixelIdxList(find(GoodBlob));
BlobWeightedCentroids = BlobWeightedCentroids(find(GoodBlob));
BlobMinorAxisLength = BlobMinorAxisLength(find(GoodBlob));

%parameter debugging

if(ToPlot)
    temp = blankframe;
    for i = 1:length(BlobPixelIdxList)
        temp(BlobPixelIdxList{i}) = temp(BlobPixelIdxList{i}) + frame(BlobPixelIdxList{i});
    end
    cutoff = PercentileCutoff(frame(:),98);
    composite = zeros(Xdim,Ydim,3);
    tempc = frame/cutoff;
    tempc(find(temp ~= 0)) = 0;
    composite(:,:,1) = frame/cutoff;
    
    composite(:,:,2) = tempc;
    composite(:,:,3) = tempc;
    
    figure(53);image(composite);axis image;pause;
end





