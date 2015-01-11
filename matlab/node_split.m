function coeff = node_split(data, labels, opt,bits);


DIM=size(data,2);
N=length(data);
coeff_a=zeros(1,DIM+1);

coeff_a=axis_p(data,labels);
impurity_axis=impurity(data,labels,coeff_a);

if opt==0
    coeff=coeff_a;
    return;
end


[coeff_opt impurity_plane]=perturb(data,labels,coeff_a,1);
j=1; J=50;
while (j<=J)
    [coeff_r impurity_plane_r]=randomization(data,labels,coeff_opt);
    if impurity_plane_r<impurity_plane
        coeff_opt=coeff_r;
        [coeff_opt impurity_plane]=perturb(data,labels,coeff_opt,1);
    end
    j=j+1;
end

coeff_one=max(abs(coeff_opt(1:DIM)));
idx=find(abs(coeff_opt)==coeff_one);
coeff_opt=coeff_opt/coeff_opt(idx);
coeff_opt(1:DIM)=round(coeff_opt(1:DIM)*2^(bits-1))/2^(bits-1);
coeff_opt(find(coeff_opt(1:DIM)==1))=1-1/2^(bits-1);
coeff_opt(find(coeff_opt(1:DIM)==-1))=-1+1/2^(bits-1);
coeff_opt(idx)=1;
[coeff_opt impurity_plane]=perturb(data,labels,coeff_opt,0);


if impurity_axis-impurity_plane<=0   
    coeff=coeff_a;
else
    coeff=coeff_opt;
end

