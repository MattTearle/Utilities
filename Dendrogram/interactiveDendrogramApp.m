classdef interactiveDendrogramApp < handle
    
    properties (Access = private)
        % Graphics objects
        fig                     % main window
        % UI elements
        DataDropDown            % data source menu
        LinkagemethodDropDown   % linkage method menu
        DistancemetricDropDown  % distance metric menu
        MakedendrogramButton    % push button
        QuantileSlider          % slider for quantile width
        SliderValueText         % text annotation for quantile slider
        % Display elements
        dendroaxes              % axes for dendrogram
        parcoordsaxes           % axes for parallelcoords plot
        dendlines               % lines in dendrogram
        thresh                  % horizontal line for clustering
        extralines              % vertical lines for leaf nodes
        
        % Dropdown menu options
        linkagemethods = {'Average','Centroid','Complete','Median','Single','Ward','Weighted'}; % Description
        dmetricsfull = {'Euclidean','Squared Euclidean','Standardized Euclidean','City block','Cosine','Correlation','Hamming','Jaccard','Mahalanobis','Spearman'};
        dmetricsabbr = {'Euclidean','SquaredEuclidean','SEuclidean','Cityblock','Cosine','Correlation','Hamming','Jaccard','Mahalanobis','Spearman'};
        
        % Internal data
        data                    % matrix of user data
        clusters                % matrix of group numbers from clustering
        ngrp                    % number of groups (at current threshold)
    end
    
    methods (Access = public)
        % Constructor
        function app = interactiveDendrogramApp
            % layout window
            buildUI(app)
            % add placeholders
            app.dendlines = gobjects(0);
            app.extralines = gobjects(0);
            app.data = [];
            % update data sources menu
            getdatasources(app,[],[])
        end
        
        function display(app) %#ok<MANU,DISPLAY>
        end
    end
    
    methods (Access = private)
        function buildUI(app)
            % Make figure window
            app.fig = figure('NumberTitle','off','Name','Interactive Dendrogram',...
                'HandleVisibility','callback',...
                'WindowButtonDownFcn',@app.getdatasources);
            app.dendroaxes = axes(app.fig,...
                'XTick',[],'YTick',[],'Color',0.975*[1 1 1],'Box','on',...
                'HandleVisibility','callback');
            % Resize figure to have second axes
            app.dendroaxes.Units = 'pixels';
            app.fig.Position(1) = app.fig.Position(1) - round(0.5*app.fig.Position(3));
            app.fig.Position(3) = 2*app.fig.Position(3);
            app.dendroaxes.Units = 'normalized';
            app.parcoordsaxes = axes(app.fig,...
                'Position',app.dendroaxes.Position + [0.5 0 0 0],...
                'XTick',[],'YTick',[],'Color',0.975*[1 1 1],'Box','on',...
                'HandleVisibility','callback');
            % Resize again to add room for UI controls
            app.dendroaxes.Units = 'pixels';
            app.parcoordsaxes.Units = 'pixels';
            app.fig.Position(2) = app.fig.Position(2) - 120;
            app.fig.Position(4) = app.fig.Position(4) + 120;
            app.dendroaxes.Units = 'normalized';
            app.parcoordsaxes.Units = 'normalized';
            
            % Add panel for UI controls
            y = app.dendroaxes.Position(2)+app.dendroaxes.Position(4);
            n = 5;
            xleft = app.dendroaxes.Position(1);
            xright = app.parcoordsaxes.Position(1)+app.parcoordsaxes.Position(3);
            ylow = y + (1-y)/n;
            yheight = (1-y)*(n-2)/n;
            pan = uipanel(app.fig,'Position',[xleft ylow (xright - xleft) yheight]);
            
            % Add UI controls
            % Dropdown menu for data source
            app.DataDropDown = uicontrol(pan,'Units','Normalized',...
                'Position',[0.05 0.3 0.1 0.2],'Style','popup',...
                'String',{''},'Callback',@app.changeoptions);
            uicontrol(pan,'Units','Normalized','Position',[0.05 0.6 0.1 0.2],...
                'Style','text','String','Data source','FontSize',10,...
                'FontWeight','bold');
            % Dropdown menu for linkage methods
            app.LinkagemethodDropDown = uicontrol(pan,'Units','Normalized',...
                'Position',[0.19 0.3 0.12 0.2],'Style','popup',...
                'String',app.linkagemethods,'Value',6,...
                'Callback',@app.changeoptions);
            uicontrol(pan,'Units','Normalized','Position',[0.19 0.6 0.12 0.2],...
                'Style','text','String','Linkage method','FontSize',10,...
                'FontWeight','bold');
            % Dropdown menu for distance metric
            app.DistancemetricDropDown = uicontrol(pan,'Units','Normalized',...
                'Position',[0.35 0.3 0.15 0.2],'Style','popup',...
                'String',app.dmetricsfull,'Value',1,...
                'Callback',@app.changeoptions);
            uicontrol(pan,'Units','Normalized','Position',[0.35 0.6 0.15 0.2],...
                'Style','text','String','Distance metric','FontSize',10,...
                'FontWeight','bold');
            
            % Button to make dendrogram
            app.MakedendrogramButton = uicontrol(pan,'Units','Normalized',...
                'Position',[0.575 0.25 0.15 0.5],'Style','pushbutton',...
                'String','Make dendrogram','Callback',@app.makedendro,...
                'Enable','off');
            
            % Slider to control quantiles in parallel coords plot
            app.QuantileSlider = uicontrol(pan,'Units','Normalized',...
                'Position',[0.8 0.3 0.15 0.2],'Style','slider',...
                'Min',0,'Max',0.5,'Callback',@app.drawparcoords);
            app.SliderValueText = uicontrol(pan,'Units','Normalized',...
                'Position',[0.8 0.6 0.15 0.2],...
                'Style','text','String','Quantile: 50%','FontSize',10,...
                'FontWeight','bold');
            
        end
        
        function makedendro(app,~,~)
            % Import the data from the base workspace
            vnm = app.DataDropDown.String{app.DataDropDown.Value};
            app.data = evalin('base',vnm);
            % Get the linkage, using the options in the menus
            lm = app.LinkagemethodDropDown.String{app.LinkagemethodDropDown.Value};
            dm = app.dmetricsabbr{app.DistancemetricDropDown.Value};
            z = linkage(app.data,lm,dm);
            % Get the matrix of group numbers & plot the dendrogram
            delete(app.dendlines) % clear any current plot
            axes(app.dendroaxes)
            app.clusters = dendrocluster(z);
            app.dendroaxes.Box = 'on';
            app.dendroaxes.XAxis.TickLength = [0 0];
            app.dendroaxes.HandleVisibility = 'callback';
            % Get the line objects
            app.dendlines = app.dendroaxes.Children;
            
            % Add threshold line in middle of axes
            app.thresh = line(app.dendroaxes,...
                app.dendroaxes.XLim,[1 1]*mean(app.dendroaxes.YLim),...
                'Color','r','LineWidth',2,'ButtonDownFcn',@app.lineClick);
            
            % Don't need to make plot again until something is changed
            app.MakedendrogramButton.Enable = 'off';
            
            % Update parallelcoords plot
            redraw(app,[],[])
        end
        
        % Update the data sources menu with variables in base workspace
        function getdatasources(app,~,~)
            cv = app.DataDropDown.String{app.DataDropDown.Value};
            % Get the variables in the base workspace
            vars = evalin('base','whos');
            if ~isempty(vars)
                % Select just doubles with more than one row
                n = cat(1,vars.size);
                idx = strcmp({vars.class}','double') & (n(:,1) > 1);
                if any(idx)
                    % Get the list of names and update the menu options
                    app.DataDropDown.String = {vars(idx).name};
                    app.DataDropDown.Value = ...
                        find(strcmp(cv,app.DataDropDown.String));
                    if isempty(app.DataDropDown.Value)
                        app.DataDropDown.Value = 1;
                    end
                else
                    app.DataDropDown.String = {''};
                end
                changeoptions(app,[],[])
            end
        end
        
        % Check the arrangement of options
        function changeoptions(app,~,~)
            % Get current linkage method option
            lm = app.LinkagemethodDropDown.String{app.LinkagemethodDropDown.Value};
            % Is distance metric = Euclidean
            if app.DistancemetricDropDown.Value == 1
                % Yes => all linkage methods are appropriate
                app.LinkagemethodDropDown.String = app.linkagemethods;
                app.LinkagemethodDropDown.Value = find(strcmp(lm,app.linkagemethods));
            else
                % No => only a subset of methods are appropriate
                subset = {'Average','Complete','Single','Weighted'};
                % If current method is inappropriate, change to default
                if ismember(lm,{'Centroid','Median','Ward'})
                    lm = 'Single';
                end
                % Update menus
                app.LinkagemethodDropDown.Value = find(strcmp(lm,subset));
                app.LinkagemethodDropDown.String = subset;
            end
            % Any change => can make a new dendrogram (as long as data
            % exists)
            if ~isempty(app.DataDropDown.String{app.DataDropDown.Value})
                app.MakedendrogramButton.Enable = 'on';
            end
        end
        
        function lineClick(app,~,~)
            % Start the callback to update the line position
            app.fig.WindowButtonMotionFcn = @app.lineMove;
            % Define the callback for when the mouse button is released
            app.fig.WindowButtonUpFcn = @app.redraw;
        end
        
        function lineMove(app,~,~)
            % Change the vertical position of the threshold line
            app.thresh.YData = app.dendroaxes.CurrentPoint(1:2,2);
        end
        
        % Make the parallelcoordinates plot
        function drawparcoords(app,~,~)
            % Update the slider value
            q = max(0.5 - app.QuantileSlider.Value,eps);
            if q < 0.5
                app.SliderValueText.String = ...
                    ['Quantile: ',num2str(round(q*100)),'% - ',num2str(round((1-q)*100)),'%'];
            else
                app.SliderValueText.String = 'Quantile: 50%';
            end
            if ~isempty(app.data)
                % Get the current groups
                g = app.clusters(:,app.ngrp-1);
                % Make the parallelcoordinates plot
                axes(app.parcoordsaxes);
                l = parallelcoords(app.data,'Group',g,'Quantile',q);
                legend('off')
                app.parcoordsaxes.Box = 'on';
                app.parcoordsaxes.HandleVisibility = 'callback';
                % Change the default colors to a spectrum
                c = parula(app.ngrp);
                % Parallelcoords with quantile option creates 3 lines for each
                % group (median and upper/lower quantiles)
                for k = 3*(1:app.ngrp)
                    l(k-2).Color = c(k/3,:);
                    l(k-1).Color = c(k/3,:);
                    l(k).Color = c(k/3,:);
                end
            end
        end
        
        function redraw(app,~,~)
            % Remove any existing vertical lines added
            delete(app.extralines)
            app.extralines = gobjects(0);
            % Stop the callback to update the line position
            app.fig.WindowButtonMotionFcn = [];
            % See how many vertical lines the threshold line crosses
            % Each dendrogram line is a staple shape => 4 X/YData values
            % (point, top corner, top corner, point). Need number of times
            % the YData for the first point/top corner pair are on either
            % side of the threshold line position. And again for the second
            % pair.
            y = cat(1,app.dendlines.YData);
            app.ngrp = sum(prod(y(:,1:2) - app.thresh.YData,2) < 0) + sum(prod(y(:,3:4) - app.thresh.YData,2) < 0);
            % Get the group designations for that number of groups
            g = app.clusters(:,app.ngrp-1);
            % Make the parallelcoordinates plot
            drawparcoords(app,[],[])
            % Update dendrogram colors to match parallel coords plot
            % Start by resetting everything
            [app.dendlines.Color] = deal(0.6*[1 1 1]);
            % Find x value between groups. To do this, see which groups at
            % the bottom of the dendrogram correspond to the groups defined
            % at the current cut level. Take the max to get the right-most
            % position. Add 0.5 to go between that group and the next. (0
            % added to give a left-hand border.)
            bndry = [0;grpstats(app.clusters(:,end),g,@max)] + 0.5;
            x = cat(1,app.dendlines.XData);
            % Color each group
            c = parula(app.ngrp);
            for k = 1:app.ngrp
                % Find the lines that live entirely between the boundaries
                idx = all(x > bndry(k),2) & all(x < bndry(k+1),2);
                if any(idx)
                    % Make them all the color of the current group
                    [app.dendlines(idx).Color] = deal(c(k,:));
                else
                    % If there aren't any, that means the current group is
                    % just a leaf node. Add a vertical line from the bottom
                    % to the threshold line. Note that the boundaries are
                    % 0.5 offset, so averaging boundary k and k+1 gives the
                    % integer value of the current group
                    app.extralines(end+1) = line(app.dendroaxes,...
                        [1 1]*round(mean(bndry(k:k+1))),...
                        [0 app.thresh.YData(1)],'Color',c(k,:));
                    % Extra line is added on top; switch it with the
                    % threshold line so the threshold line stays on top
                    app.dendroaxes.Children(1:2) = app.dendroaxes.Children(2:-1:1);
                end
            end
        end

    end
    
end
