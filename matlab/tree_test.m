function err=tree_test(data, labels, coeff, class_id);

class=unique(labels);
class=length(class);
depth=ceil(log2(class));

for i=1:size(data,1)
    inode=1;
    for idepth=1:depth
        V=sum([data(i,:) 1].*coeff{idepth}(inode,:));
        if V>=0
            child=1;
        else
            child=2;
        end
        inode=2*(inode-1)+child;
        if idepth==depth-1
            if class_id{1}(inode)~=0
                idtest(i)=class_id{1}(inode);
                break;
            end
        end
        if idepth==depth
            idtest(i)=class_id{2}(inode);
        end
    end
    
end

err=sum(labels~=idtest')/length(labels);