% an example to construct an oblique decision tree with the specified
% resolution in 2D space.

clear
close all

bits=2; % specify the resolution

%% create data samples with 6 classes in 2D space
mu=[0 2];
sigma=[1 0;0 1];
N=200;
data1=mvnrnd(mu,sigma,N);
mu=[-4 -1];
data2=mvnrnd(mu,sigma,N);
mu=[-1 -4];
data3=mvnrnd(mu,sigma,N);
mu=[-1 7];
data4=mvnrnd(mu,sigma,N);
mu=[-5 5];
data5=mvnrnd(mu,sigma,N);
mu=[-5 -7];
data6=mvnrnd(mu,sigma,N);
data=[data1;data2;data3;data4;data5;data6];


labels=[ones(1,N) 2*ones(1,N) 3*ones(1,N) 4*ones(1,N) 5*ones(1,N) 6*ones(1,N)]';

plot(data1(:,1),data1(:,2),'o')
hold on
plot(data2(:,1),data2(:,2),'ro')
plot(data3(:,1),data3(:,2),'go')
plot(data4(:,1),data4(:,2),'yo')
plot(data5(:,1),data5(:,2),'co')
plot(data6(:,1),data6(:,2),'mo')

%%

[coeff class_id]=tree_split(data, labels, bits);
err=tree_test(data, labels, coeff, class_id);
boundaryplot2d(data,labels,coeff);
title(['an oblique decision tree with ',num2str(bits), ' bit resolution'])
