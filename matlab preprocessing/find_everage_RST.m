function [indexQ indexR indexS indexT sumData] = find_everage_RST(twelveLeadECG, Fs)
% load 'E:\在元智大学\PTB Database\ill\s0020arem.mat';
% twelveLeadECG = val(:,1:10000);
 Fs = 1000;
[m n] = size(twelveLeadECG);
if m>n;
    twelveLeadECG = twelveLeadECG';
end

len = length(twelveLeadECG);
nbrChl = size(twelveLeadECG, 1);


blcutoff = round(0.75*len/(Fs/2)); %0.75Hz baseline cutoff point
hfcutoff = round(45*len/(Fs/2)); %45Hz high frequency noise cutoff point

sumData = zeros(1, len);
noBaselineData = zeros(nbrChl, len);
for t = 1:nbrChl
    srcData = twelveLeadECG(t, :);
    dctData = dct(srcData);
    %     dctData(1:20) = 0;
    %     dctData(200:end) = 0;%一直用1000，4E:\在元智大学\謝瑞建\原始有病\s0017lrem.mat需要460
    tmp = zeros(1, len);
    tmp(blcutoff:hfcutoff)=1;
    tmp = tmp.*dctData;
    idctData = idct(tmp);
    noBaselineData(t, :) = idctData;
    idctData = idctData - median(idctData);
    sumData = sumData + abs(idctData);
end
% [U,S,V] = svd(noBaselineData);
% M = noBaselineData'*U(:,1:3);
% subplot(3, 1, 1)
% plot(M(:,1))
% subplot(3, 1, 2)
% plot(M(:,2))
% subplot(3, 1, 3)
% plot(M(:,3))


[R, indexR] = find_highest_peaks(sumData, sumData, 4); %原始有病\s0015lrem.mat'和's0029lrem'0.75
%%%=======
% plot(sumData)
% hold on
% plot(indexR, sumData(indexR), 'r+');
% plot(1:len, 4*mean(sumData), 'r');

%%%=======
heartLen = round(mean(diff(indexR)));
nbrPeaks = length(indexR);
oneFifthHL = round(heartLen/5);%health\s0496_rem needs 1/5，for other cases, 1/4 is ok。
oneFourthHL = round(heartLen/4);
twoThirdHL = round(2*heartLen/3);
%% search for S points
RTdata = zeros(1, len);
oneFifthFromR = indexR(1:end-1)+oneFifthHL;%the S besides the last R is ignored
for i = 1:nbrPeaks-1;
    RTdata(indexR(i):oneFifthFromR(i)) = max(R) - sumData(indexR(i):oneFifthFromR(i));
end

S = zeros(1, nbrPeaks-1);
indexS = zeros(1, nbrPeaks-1);

for i = 1:nbrPeaks-1;
    [S(i) indexS(i)] =  max(RTdata(indexR(i):oneFifthFromR(i)));
    indexS(i) = indexR(i) + indexS(i);
end

meanS = mean(S);
for i = 1:nbrPeaks-1;
    RTdata(indexR(i):oneFifthFromR(i)) = RTdata(indexR(i):oneFifthFromR(i)) - S(i) + meanS;
end

threshold = diff(RTdata);
threshold(threshold<0) = 0;
cutoff = 8*mean(threshold);% ill\s0092lrem,
% % cutoff = 0.2*max(threshold);%health\s0496_rem needs 0.2，for other cases, 0.1 is ok。
if cutoff>0.8*max(threshold);
    cutoff = 0.8*max(threshold);
end
threshold(threshold>cutoff) = cutoff;
t = 1;

for i = 1:length(threshold)-1
    if threshold(i)==cutoff && threshold(i+1)~=cutoff
        down(t) = i;
        t = t + 1;
    end
end


% diffDown = diff(down);
% indexS(1:end-1) =  down((diffDown>0.5*max(diffDown)));%indexS stands the last down at this time
% indexS(end) = down(end);

for i = 2:nbrPeaks
    tmp = down+1 - indexR(i);
    index = find(tmp<0);
    indexS(i-1) = down(index(end));%indexS stands the last down at this time
end

for i = 1:nbrPeaks-1
    for j = 1:oneFourthHL;
        if threshold(indexS(i)+j)~=0 && threshold(indexS(i)+j+1)==0
            indexS(i) = indexS(i)+j+1;
            break;
        end
    end
end% find the first turning point after the last DOWN of each heartbeat


% meanRS = round(mean(indexS-indexR(1:end-1)));
% indexS = indexR(1:end-1) + meanRS;
%%%=======
% plot(indexS, sumData(indexS), 'g+');
%%%=======
%% search for Q points
PRdata = zeros(1, len);
oneFifthFromR=zeros(1, nbrPeaks);
oneFifthFromR(2:end) = indexR(2:end)-oneFifthHL;%the Q besides the first R is ignored

for i = 2:nbrPeaks;
    PRdata(oneFifthFromR(i):indexR(i)) = max(R) - sumData(oneFifthFromR(i):indexR(i));
end

indexQ = zeros(1, nbrPeaks-1);


threshold = diff(PRdata);
threshold(threshold>0) = 0;
threshold = abs(threshold);

cutoff = 8*mean(threshold);% ill\s0092lrem,
% % cutoff = 0.2*max(threshold);%health\s0496_rem needs 0.2，for other cases, 0.1 is ok。
if cutoff>0.6*max(threshold);
    cutoff = 0.6*max(threshold);
end
threshold(threshold>cutoff) = cutoff;

t = 1;
for i = 1:length(threshold)-1
    if threshold(i)~=cutoff && threshold(i+1)==cutoff
        up(t) = i+1;
        t = t + 1;
    end
end
%%%=============
% figure(2)
% plot(threshold)
% hold on
% plot(up, threshold(up), 'r+')
% % plot(indexR, threshold(indexR), 'rs')
% figure(3)
%%%=============
for i = 1:nbrPeaks-1    
    tmp = up  -1 - indexR(i);
    index = find(tmp>0);
    indexQ(i) = up(index(1))-30;%indexQ stands the last down at this time
end


% meanQR = round(mean(indexR(2:end)-indexQ));
% 
% if indexR(1)-meanQR>0
%     indexQ = [indexR(1) - meanQR, indexQ];
% end

%%%=======
% plot(indexQ, sumData(indexQ), 'm+');
% 
% figure(2)
% plot(threshold);
% hold on
% plot(indexQ, threshold(indexQ), 'm+');
%%%=======

%%
T = zeros(1, nbrPeaks-1);
indexT = zeros(1, nbrPeaks-1);

for i = 1:nbrPeaks-1;
    [T(i) indexT(i)] =  max(sumData(indexR(i)+oneFifthHL:indexR(i)+twoThirdHL));
    indexT(i) = indexR(i)+oneFifthHL + indexT(i)+1;
end

meanRT = round(mean(indexT-indexR(1:end-1)));
sdtRT = std(indexT-indexR(1:end-1));
RT = indexT - indexR(1:end-1);
outIndex = find((abs(RT-meanRT))>sdtRT);
if ~isempty(outIndex)
    indexT(outIndex) = indexR(outIndex) + meanRT;
end

