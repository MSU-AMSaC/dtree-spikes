
function coeff=axis_p(data,labels);

DIM=size(data,2);
N=length(data);
coeff=eye(DIM);
coeff(:,end+1)=0;

class=length(unique(labels));
x=floor(class/2);
impurity_a_min=x/class*log2(x)+(class-x)/class*log2(class-x);

for i=1:size(coeff,1)
    [coeff(i,:) impurity_plane(i)]=perturb(data,labels,coeff(i,:),0);
end

idx=find(impurity_plane==min(impurity_plane));

for i=1:length(idx)
    tmp=data.*repmat(coeff(i,1:DIM),N,1);
    tmp=abs((sum(tmp'))'+coeff(i,end));
    for j=1:class
        V2(j)=sum(tmp(find(labels==j)));
    end
    V2=nchoosek(V2,2);
    V2=sum(V2');
    V(i)=min(V2);
end

coeff=coeff(idx,:);
idx=find(V==max(V));
idx=idx(1);
coeff=coeff(idx,:);
