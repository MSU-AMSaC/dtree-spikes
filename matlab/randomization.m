function [coeff impurity_plane]=randomization(data,labels,coeff);
N=length(data);
DIM=size(data,2);

rvector=(rand(1,DIM+1)-0.5)*2;

V=data.*repmat(coeff(1:DIM),N,1);
V=(sum(V'))'+coeff(end);

R=data.*repmat(rvector(1:DIM),N,1);
R=(sum(R'))'+rvector(end);

candidates=-V./R;
[candidates idx]=sort(candidates);
labels_sort=labels(idx);

for i=1:N-1
        for j=1:DIM
            if isempty(find(labels_sort(1:i)==j))
                Pro1(j)=0.00001;
            else
                Pro1(j)=length(find(labels_sort(1:i)==j))/i;
            end
            
            if isempty(find(labels_sort(i+1:N)==j))
                Pro2(j)=0.00001;
            else
                Pro2(j)=length(find(labels_sort(i+1:N)==j))/(N-i);
            end                     
        end
        impurity_alpha(i)=-i*sum(Pro1.*log2(Pro1))-(N-i)*sum(Pro2.*log2(Pro2));
        impurity_alpha(i)=impurity_alpha(i)/N;
end

 [min_impurity_alpha idx]=min(impurity_alpha);
 
 alpha=(candidates(idx)+candidates(idx+1))/2;
 coeff=coeff+rvector*alpha;
 impurity_plane=impurity(data,labels,coeff);
    
