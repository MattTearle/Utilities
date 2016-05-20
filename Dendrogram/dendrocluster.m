function clust = dendrocluster(z,varargin)
% CLUST = DENDROCLUSTER(Z) creates a dendrogram from the linkage matrix Z
% and returns a matrix CLUST of cluster numbers for the observations. Each
% row of CLUST corresponds to an observation in the original data. Each
% column corresponds to a split in the dendrogram. Hence the first column
% corresponds to clustering the data into two groups defined by the first
% split in the dendrogram; the second column to three clusters defined by
% the second split; etc.
%
% The clusters are consistently ordered according to their appearance in
% the dendrogram; for a vertical dendrogram, the clusters 1:k correspond to
% the splits shown left-to-right in the dendrogram. For example:
%         -------------
%         1           2
%      -------        |
%      1     2        3
%      |     |     -------
%      1     2     3     4
%      |     |     |     |
%      |     |   -----   |
%      1     2   3   4   5
%      |     |   |   |   |
% etc
%
% CLUST = DENDROCLUSTER(Z,...) accepts any other arguments accepted by
% DENDROGRAM.
%
% Example:
% rng(123)
% x = rand(200,4);
% z = linkage(x,'ward');
% g = dendrocluster(z);
% figure
% subplot(2,1,1)
% parallelcoords(x,'Group',g(:,2),'Quantile',0.25)
% subplot(2,1,2)
% parallelcoords(x,'Group',g(:,3),'Quantile',0.25)

% Make dendrogram and keep outputs
[l,node] = dendrogram(z,varargin{:});
nleaf = 1 + length(l);
ax = l(1).Parent;

% Get order of group labels on the axes
if isequal(abs(diff(l(1).YData)) > 0,[1 0 1])
    % Check orientation of dendrogram
    ord = str2double(cellstr(ax.XTickLabel));
else
    ord = str2double(cellstr(ax.YTickLabel));
end
[~,axidx] = sort(ord);

% Get cluster number for each observation at each cluster level
g = cluster(z,2:nleaf);

% Get mapping of cluster numbers as given by CLUSTER and the node number
% given by DENDROGRAM
nodeord = unique([g(:,end),node],'rows');
% Now map that to the x-axis location
nodeord = axidx(nodeord(:,2));

% Sort the clusters by leaf node order (left-to-right by axis)
[~,gidx] = sort(nodeord(g(:,end)));
clust = g(gidx,:);
% Renumber (left-to-right by axis) at each level
clust = cumsum([ones(1,29);(diff(clust)~=0)]);
% Sort numbers back into original order
[~,gidx] = sort(gidx);
clust = clust(gidx,:);
