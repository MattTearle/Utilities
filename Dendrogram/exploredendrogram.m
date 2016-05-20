rng(123)
x = rand(200,4);
z = linkage(x,'ward');
[l,node] = dendrogram(z);

%%
ax = l(1).Parent;
ord = str2double(cellstr(ax.XTickLabel));
[~,axidx] = sort(ord);

g = cluster(z,2:30);

nodeord = unique([g(:,end),node],'rows');

nodeord = axidx(nodeord(:,2));

%%

[~,gidx] = sort(nodeord(g(:,end)));
gsort = g(gidx,:);
gsort = cumsum([ones(1,29);(diff(gsort)~=0)]);
[~,gidx] = sort(gidx);
xsort = x(gidx,:);
gsort = gsort(gidx,:);

%%
% Click on something
yvals = cat(1,l.YData);
xvals = cat(1,l.XData);
k = find(gco == l);
all(yvals < max(yvals(k,[1,4])),2)

centers = mean(xvals(:,2:3),2);
% left hand
find(min(xvals(k,:))==centers)
% right hand
find(max(xvals(k,:))==centers)
% repeat until leaves are reached

%%
l(k).Color = 'r';
l(min(xvals(k,:))==centers).Color = 'r';
l(max(xvals(k,:))==centers).Color = 'r';

