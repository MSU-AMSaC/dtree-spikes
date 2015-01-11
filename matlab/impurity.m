function [info info_L info_R]=impurity(data, labels, coeff);

N=length(data);
DIM=size(data,2);
V=data.*repmat(coeff(1:DIM),N,1);
V=(sum(V'))'+coeff(end);
idxp=find(V>0);
idxn=find(V<=0);
labels_p=labels(idxp);
labels_n=labels(idxn);
class=unique(labels);

for i=1:length(class)
    if isempty(find(labels_p==class(i)))
        Pro1(i)=0.00001;
    else
        Pro1(i)=length(find(labels_p==class(i)))/length(labels_p);
    end
    
    if isempty(find(labels_n==class(i)))
        Pro2(i)=0.00001;
    else
        Pro2(i)=length(find(labels_n==class(i)))/length(labels_n);
    end
    
end

info_L=-sum(Pro1.*log2(Pro1));
info_R=-sum(Pro2.*log2(Pro2));
info=+length(labels_p)*info_L/N+length(labels_n)*info_R/N;
