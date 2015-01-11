function [coeff impurity_plane]=perturb(data,labels,coeff,opt);
N=length(data);
DIM=size(data,2);
V=data.*repmat(coeff(1:DIM),N,1);
V=(sum(V'))'+coeff(end);
class=unique(labels);
Nclass=length(class);
Pstag=1;
if opt==0
    dim_start=DIM+1;
else
    dim_start=1;
end

for dim=dim_start:DIM+1
    if dim==DIM+1
        U=V;
    else
        U=V./data(:,dim);
    end
    
    candidates=coeff(dim)-U;
    [candidates idx]=sort(candidates);
    labels_sort=labels(idx);
    for i=1:N-1
        for j=1:Nclass
            if isempty(find(labels_sort(1:i)==class(j)))
                Pro1(j)=0.00001;
            else
                Pro1(j)=length(find(labels_sort(1:i)==class(j)))/i;
            end
            
            if isempty(find(labels_sort(i+1:N)==class(j)))
                Pro2(j)=0.00001;
            else
                Pro2(j)=length(find(labels_sort(i+1:N)==class(j)))/(N-i);
            end                     
        end
        impurity_coeff(i)=-i*sum(Pro1.*log2(Pro1))-(N-i)*sum(Pro2.*log2(Pro2));
        impurity_coeff(i)=impurity_coeff(i)/N;
    end
    [min_impurity_coeff idx]=min(impurity_coeff);
    
    coeff_new=coeff;
    coeff_new(dim)=(candidates(idx)+candidates(idx+1))/2;
    
    impurity_plane=impurity(data,labels,coeff);
    impurity_plane_new=impurity(data,labels,coeff_new);
    if impurity_plane-impurity_plane_new>0.001
        coeff=coeff_new;
        impurity_plane=impurity_plane_new;
        Pstag=1;
    else
        if Pstag>rand(1)
            coeff=coeff_new;
            impurity_plane=impurity_plane_new;
        end
        Pstag=Pstag-0.1*Pstag;
    end
end
