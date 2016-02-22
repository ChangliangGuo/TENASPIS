function [ output_args ] = BrowseOverlaps(moviefile,NeuronID,cx )
close all;

% load basic shit
load('ProcOut.mat','NeuronPixels','NeuronImage','NumNeurons','NumFrames','FT');
load ExpTransients.mat;
load NormTraces.mat;
load pPeak.mat;
load expPosTr.mat;


t = (1:NumFrames)/20;



buddies = [];
for i = 1:NumNeurons
    if (i == NeuronID)
        continue;
    end
    
    if (length(intersect(NeuronPixels{i},NeuronPixels{NeuronID})) > 0)
        buddies = [buddies,i];
    end
end

figure(1);
a(1) = subplot(length(buddies)+1,1,1);
plot(zscore(trace(NeuronID,:)));hold on;plot(FT(NeuronID,:)*5);axis tight;plot(expPosTr(NeuronID,:)*5,'-r','LineWidth',3);

for i = 1:length(buddies)
    a(i+1) = subplot(length(buddies)+1,1,i+1);
    plot(zscore(trace(buddies(i),:)));hold on;plot(expPosTr(buddies(i),:)*5,'-r');title(int2str(buddies(i)));
    axis tight;
end
 linkaxes(a,'x');
 set(gcf,'Position',[437    49   883   948])
 
 while(1)
     pause;
 figure(1)
 display('pick a time to see the frame')
 [mx,my] = ginput(1);
 f = loadframe(moviefile,mx);
 figure(2);set(gcf,'Position',[1130         337         773         600]);
 
 [~,maxidx] = max(f(NeuronPixels{NeuronID}));
 peakpeak = pPeak{NeuronID}(maxidx);
 peakrank = mRank{NeuronID}(maxidx);
 
 imagesc(f);caxis(cx);title(['peak=',num2str(peakpeak),' rank=',num2str(peakrank)]);
 hold on
 [b] = bwboundaries(NeuronImage{NeuronID});
 b = b{1};
 plot(b(:,2),b(:,1),'g');
 for i = 1:length(buddies)
   [b] = bwboundaries(NeuronImage{buddies(i)});colormap gray;   
   b = b{1};
   plot(b(:,2),b(:,1),'r');
 end
 hold off;
 end

