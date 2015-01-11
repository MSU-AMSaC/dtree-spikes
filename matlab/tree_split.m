function [coeff, class_id]=tree_split(data, labels, bits)

% tree_split constructs a quantized oblique decison tree on the n by p 
% matrix data. Each row of data corresponds to a sample in p dimensional space.
% labels stores class labels for data in an n by 1 array. A class label
% should be an integer greater than zero. bits represents the resolution of
% coefficients for a hyperplane and should be an integer greater than zero.
% If bits is one, the function returns an axis-parallel decision tree.
% Otherwise, it returns an oblique decision tree with the specified quantization.

% The function returns the tree structure stored in coeff with one by
% Ndepth cell array. Ndepth means the depth of the tree, equal to
% ceiling(log2(Nclass)), where Nclass means the number of classes in data. The
% ith cell contains 2^(i-1) elements. If the coefficients of an element are
% zero, the element represents a leaf node. The class label of a leaf node
% is stored in class_id as a 1 by 2 cell array. The first cell
% corresponds to the last but one depth with size of 2^(Ndepth-1)and the
% second cell corresponds the last depth with size of 2^Ndepth. A zero will
% be assigned if it is not a leaf node.
%
% If a tree structure is like the diagram below, then coeff is a 1 by 3 array, such
% that coeff = [{N1}, {N2, N3}, {0, N4, 0, N5}].
% class_id = [{1, 0, 2, 0}, {0, 0, 3, 4, 0, 0, 5, 6}]
%            N1
%           / \
%         N2   N3
%        / \   / \
%       1  N4 2  N5
%         / \    / \
%        3   4  5   6
% 
% For more detailed information about the algorithm for creating the oblique decision
% tree, please refer to
% S. K. Murthy, S. Kasif, and S. Salzberg, "A system for induction of
% oblique decision trees," J. Artif. Int. Res., vol. 2, pp. 1-32, 1994.

if bits==1
    opt=0;
else
    opt=1;
end


class=unique(labels);
class=length(class);
depth=ceil(log2(class));

DIM=size(data,2);
N=length(data);

attribute_min=min(data)-1;
data=data-repmat(attribute_min,N,1);



%% 

data_tree{1}=data;
labels_tree{1}=labels;

for idepth=1:depth
    if idepth<=depth-1
        for inode=1:2^(idepth-1)
            coeff{idepth}(inode,:) = node_split(data_tree{inode}, labels_tree{inode}, opt,bits);
            Ndata=size(data_tree{inode},1);
            V=data_tree{inode}.*repmat(coeff{idepth}(inode,1:DIM),Ndata,1);
            V=(sum(V'))'+coeff{idepth}(inode,end);
            
            idx=find(V>0);
            data_child{2*(inode-1)+1}=data_tree{inode}(idx,:);
            labels_child{2*(inode-1)+1}=labels_tree{inode}(idx);
            
            idx=find(V<=0);
            data_child{2*(inode-1)+2}=data_tree{inode}(idx,:);
            labels_child{2*(inode-1)+2}=labels_tree{inode}(idx);
            
            if idepth==depth-1
                [impurity_p impurity_node(2*(inode-1)+1) impurity_node(2*(inode-1)+2)]=impurity(data_tree{inode}, labels_tree{inode},coeff{idepth}(inode,:));
            end
            
        end
        
        data_tree=data_child;
        labels_tree=labels_child;
        clear data_child labels_child
    end
    
    if idepth==depth
        leafclass=2^idepth-class;
        if leafclass ~=0
            [impurity_depth idx]=sort(impurity_node);
            class_id{1}=zeros(1,2^(idepth-1));
            for ileafclass=1:leafclass
                table=tabulate(labels_tree{idx(ileafclass)});
                class_id{1}(idx(ileafclass))=table(find(table(:,2)==max(table(:,2))),1);
                coeff{idepth}(idx(ileafclass),:)=zeros(1,DIM+1);
            end
            
            idx_split=setdiff([1:2^(depth-1)],idx(1:leafclass));
            class_id{2}=zeros(1,2^idepth);
            for isplit=1:2^(idepth-1)-leafclass
                coeff{idepth}(idx_split(isplit),:) = node_split(data_tree{idx_split(isplit)}, labels_tree{idx_split(isplit)}, opt,bits);
                Ndata=size(data_tree{idx_split(isplit)},1);
                V=data_tree{idx_split(isplit)}.*repmat(coeff{idepth}(idx_split(isplit),1:DIM),Ndata,1);
                V=(sum(V'))'+coeff{idepth}(idx_split(isplit),end);
                
                idx=find(V>0);
                labels_child=labels_tree{idx_split(isplit)}(idx);
                table=tabulate(labels_child);
                class_id{2}(2*(idx_split(isplit)-1)+1)=table(find(table(:,2)==max(table(:,2))),1);
                
                idx=find(V<=0);
                labels_child=labels_tree{idx_split(isplit)}(idx);
                table=tabulate(labels_child);
                class_id{2}(2*(idx_split(isplit)-1)+2)=table(find(table(:,2)==max(table(:,2))),1);
                
            end
        end
        
        if leafclass ==0
            class_id{1}=zeros(1,2^(idepth-1));
            class_id{2}=zeros(1,2^idepth);
            for isplit=1:2^(idepth-1)
                coeff{idepth}(isplit,:) = node_split(data_tree{isplit}, labels_tree{isplit}, opt,bits);
                Ndata=size(data_tree{isplit},1);
                V=data_tree{isplit}.*repmat(coeff{idepth}(isplit,1:DIM),Ndata,1);
                V=(sum(V'))'+coeff{idepth}(isplit,end);
                
                idx=find(V>0);
                labels_child=labels_tree{isplit}(idx);
                table=tabulate(labels_child);
                class_id{2}(2*(isplit-1)+1)=table(find(table(:,2)==max(table(:,2))),1);
                
                idx=find(V<=0);
                labels_child=labels_tree{isplit}(idx);
                table=tabulate(labels_child);
                class_id{2}(2*(isplit-1)+2)=table(find(table(:,2)==max(table(:,2))),1);
                
            end
            
        end
        
    end
%     
end


%%

for idepth=1:depth
    for i=1:size(coeff{idepth},1)
        coeff_unnormalize{idepth}(i,:)=coeff{idepth}(i,:);
        if sum(coeff{idepth}(i,:)~=0)~=0
            coeff_unnormalize{idepth}(i,DIM+1)=coeff{idepth}(i,DIM+1)-sum(coeff{idepth}(i,1:DIM).*attribute_min);
        end
    end
    
end

coeff=coeff_unnormalize;

