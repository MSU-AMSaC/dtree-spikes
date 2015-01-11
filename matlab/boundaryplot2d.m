function boundaryplot2d(data, labels, coeff);
class=unique(labels);
depth=ceil(log2(length(class)));

xmin=min(data(:,1));
xmax=max(data(:,1));
ymin=min(data(:,2));
ymax=max(data(:,2));

A=[coeff{1}(1:2); 1 0];
B=[-coeff{1}(3); xmin];
warning off
C(:,1)=inv(A)*B;
B=[-coeff{1}(3); xmax];
C(:,2)=inv(A)*B;

A=[coeff{1}(1:2); 0 1];
B=[-coeff{1}(3); ymin];
C(:,3)=inv(A)*B;
B=[-coeff{1}(3); ymax];
C(:,4)=inv(A)*B;
warning on

C=C';
idx=find(C(:,1)<=xmax & C(:,1)>=xmin & C(:,2)<=ymax & C(:,2)>=ymin);
plot(C(idx,1),C(idx,2),'k')
hold on
clear C

if depth==1
    return;
end

for idepth=2:depth
    for i=1:2^(idepth-1)
        if sum(coeff{idepth}(i,:)~=0)~=0
            iparent=i;
            for j=1:idepth-1
                iparent=ceil(iparent/2);
                A=[coeff{idepth}(i,1:2); coeff{idepth-j}(iparent,1:2);];
                B=[-coeff{idepth}(i,3); -coeff{idepth-j}(iparent,3)];
                warning off
                C(:,j)=inv(A)*B;
                warning on
            end
            
            A=[coeff{idepth}(i,1:2); 1 0];
            B=[-coeff{idepth}(i,3); xmin];
            warning off
            C=[C inv(A)*B];
            B=[-coeff{idepth}(i,3); xmax];
            C=[C inv(A)*B];
            
            A=[coeff{idepth}(i,1:2); 0 1];
            B=[-coeff{idepth}(i,3); ymin];
            C=[C inv(A)*B];
            B=[-coeff{idepth}(i,3); ymax];
            C=[C inv(A)*B];
            warning on
            
            C=C';
%             iparent=ceil(i/2);
%             V=C.*repmat(coeff{idepth-1}(iparent,1:2),size(C,1),1);
%             V=(sum(V'))'+coeff{idepth-1}(iparent,3);
            
            iparent=i;
            ichild=i;
            for j=1:idepth-1
                iparent=ceil(iparent/2);
                V=C.*repmat(coeff{idepth-j}(iparent,1:2),size(C,1),1);
                V=(sum(V'))'+coeff{idepth-j}(iparent,3);
                if mod(ichild,2)==1
                    idx=find(V>=0-10^(-6));
                    V=V(idx);
                    C=C(idx,:);
                else
                    idx=find(V<=0+10^(-6));
                    V=V(idx);
                    C=C(idx,:);
                end
                ichild=ceil(ichild/2);
            end
            
            idx=find(C(:,1)<=xmax & C(:,1)>=xmin & C(:,2)<=ymax & C(:,2)>=ymin);
            V=V(idx);
            C=C(idx,:);
            
%             V(1)=[];
            if mod(i,2)==1
                [V idx]=sort(V);
                C=C(idx(1:2),:);
            else
                [V idx]=sort(V,'descend');
                C=C(idx(1:2),:);
            end
%             idx=idx+1;
%             idx=idx(1);
%             C=[C(1,:); C(idx,:)];
            plot(C(:,1),C(:,2),'k')
            clear C
        end
    end  
end