function ln = interactivedendrogram(x,z,varargin)

% Make dendrogram and keep outputs
[l,node] = dendrogram(z,varargin{:});
nleaf = 1 + length(l);
ax = l(1).Parent;

% originalcolors = {l.Color};

% Check orientation of dendrogram
isvertical = isequal(abs(diff(l(1).YData)) > 0,[1 0 1]);
% Get order of group labels on the axes
if isvertical
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

% For callbacks, get x and y info of the lines in the dendrogram
xvals = cat(1,l.XData);
xvals = sort(xvals(:,2:3),2);
yvals = cat(1,l.YData);

% Make a variable to hold indices of selected observations (easy way to
% make global scope within nested function callbacks)
obs = [];

% Add context menu to the dendrogram
cmenu = uicontextmenu('Callback',@(obj,e) lineclick(obj,e,[]));
[l.UIContextMenu] = deal(cmenu);

if nargout
    ln = l;
end

    function lineclick(obj,e,prevobs)
        if ~isempty(prevobs) && (e.Button ~= 1)
            %             cmenu.Children = [];
            [l.ButtonDownFcn] = deal([]);
            return
        end
        delete(cmenu.Children)
        
        k = find(gco == l);
        cp = ax.CurrentPoint;
        cpx = cp(1,1);
        cpy = cp(1,2);
        isvertline = (min(abs(xvals(k,:) - cpx)) < min(abs(yvals(k,:) - cpy)));
        if xor(isvertline,isvertical)
            expt = uimenu(cmenu,'Label','Export observation indices to workspace');
            pcds = uimenu(cmenu,'Label','Make parallel coordinates plot');
            cmpw = uimenu(cmenu,'Label','Compare with...');
        else
            %             l(k).YData
            %             d = abs(l(k).XData - cpx)
            %             ymin = min(l(k).YData(d == min(d)))
            %             if ymin
            %                 k = find((sum(bsxfun(@ge,l(k).XData(d == min(d)),xvals),2)==1) & (yvals(:,2) == ymin));
            %             end
            disp('vertical')
            return
        end
        
        m = (nleaf-k-1);
        if m
            whatchanged = unique(g(:,m:m+1),'rows');
            %         obs = find(g(:,(nleaf-k-1)) == find(histcounts(whatchanged(:,1),'BinMethod','integers')==2));
            obs = g(:,m) == find(histcounts(whatchanged(:,1),'BinMethod','integers')==2);
            
            leaves = sort(nodeord(unique(g(obs,end))));
        else
            obs = true(size(g,1),1);
            leaves = (1:nleaf)';
        end
        %         graphleafnames = ord(leaves);
        
        if isequal(obj.Type,'uicontextmenu')
            %             [l.Color] = originalcolors{:};
            [l.LineWidth] = deal(1);
        end
        % children = (xvals(:,1) >= leaves(1)) & (xvals(:,2) <= leaves(end));
        % [l(children).Color] = deal('r');
        children = find((xvals(:,1) >= leaves(1)) & (xvals(:,2) <= leaves(end)));
        for k = children(:)'
            %             l(k).Color = 0.85*(1 - l(k).Color);
            l(k).LineWidth = l(k).LineWidth + 1;
        end
        if isequal(obj.Type,'uicontextmenu')
            expt.Callback = @(~,~) assignin('base','obsidx',find(obs));
            pcds.Callback = @makepcplot;
            cmpw.Callback = @compare;
        else
            % TODO: fix issue of selecting sub/supersets for comparison
            figure
            idx = 2*obs;
            idx(prevobs) = 1;
            parallelcoords(x(idx>0,:),'Group',idx(idx>0),'Quantile',0.25)
        end
        [l.ButtonDownFcn] = deal([]);
    end

    function makepcplot(~,~)
        figure
        parallelcoords(x(obs,:))
    end

    function compare(~,~)
        [l.ButtonDownFcn] = deal(@(obj,e) lineclick(obj,e,obs));
    end

end
