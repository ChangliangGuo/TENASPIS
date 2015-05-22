function [MeanBlobs] = MakeMeanBlobs(NumNeurons,c)
% Computes the mean value of all pixels in a neuron's "Blob"

load Segments.mat;
load CC.mat;

for i = 1:max(c)
    MeanBlobs{i} = [];
end

for i = 1:length(SegChain)
    CurrNeuron = c(i)
    if (isempty(MeanBlobs{CurrNeuron}))
        MeanBlobs{CurrNeuron} = zeros(Xdim,Ydim);
        NumFrames(CurrNeuron) = 0;
    end

    
    for j = 1:length(SegChain{i})
        FrameNum = SegChain{i}{j}(1);
        ObjNum = SegChain{i}{j}(2);
        ts = regionprops(cc{FrameNum},'all');
        tempFrame = zeros(Xdim,Ydim);
        %keyboard;
        tempFrame(ts(ObjNum).PixelIdxList) = 1;
        MeanBlobs{CurrNeuron} = MeanBlobs{CurrNeuron} + tempFrame;
        NumFrames(CurrNeuron) = NumFrames(CurrNeuron) + 1;
    end

    

end
keyboard;
