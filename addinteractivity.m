function addinteractivity(gobj,fun)
% Add mouseover callback to plot objects
%
% ADDINTERACTIVITY(GOBJ,FUN) adds the callback function FUN to the graphics
% objects GOBJ such that FUN is executed when the mouse is hovered over the
% objects.
%
% If GOBJ is an array, it must contain all the same type of object. The
% graphics objects should be some kind of plot objects (line, bar, area,
% etc.) FUN must be a valid callback function handle: two inputs, the first
% being the object. FUN should modify only the properties of the object
% itself. The function should, y'know, work with the given kind of object
% in GOBJ. That's up to you.
%
% Note: you cannot have click (button down) interactivity as well as this
% mouseover interactivity. Sorry. Also, don't use callbacks that reference
% the current properties (eg LineWidth -> 2*LineWidth), as this can lead to
% nasty feedback loops.
%
% Examples:
% l = plot(rand(5));  % array of lines
% f = @(x,~) set(x,'LineWidth',2,'Color','r');
% addinteractivity(l,f)  % hovering over a line will make it thick and red
%
% a = area(rand(5));
% f = @(x,~) set(x,'FaceAlpha',0.1);
% addinteractivity(a,f)

% Basic input checking
checkinputs(gobj,fun)

% Get the ancestor objects
fig = ancestor(gobj(1),'figure');
ax = ancestor(gobj(1),'axes');
% Make a matrix of axis limits 
% (for use in the callback to check mouse position)
axlim = [ax.XLim;ax.YLim;ax.ZLim]';

% Add FUN to GOBJ as the button down (click) callback. Basic idea of this
% entire function is that it creates mouse clicks behind the scenes
set(gobj,'ButtonDownFcn',fun)
% Destroy the callback we're about to make once the graphics objects are
% destroyed
set(gobj,'DeleteFcn',@(a,b) set(fig,'WindowButtonMotionFcn',[]))

% Keep a copy of the graphics properties (so we can reset later)
% Get a struct array of all the current property settings
objprops = get(gobj);
% Get a list of the settable properties
props = fieldnames(set(gobj(1)));
% Get a list of all the properties
allprops = fieldnames(objprops);
% Get the non-settable property names...
idx = ~ismember(allprops,props);
% ...and remove them from the struct array
objprops = rmfield(objprops,allprops(idx));

% Add a callback to the mouse movement
fig.WindowButtonMotionFcn = @(a,b) figurecallback(a,b,ax,axlim,gobj,objprops);


% Mouse movement callback
function figurecallback(~,~,ax,axlim,gobj,gobjprops)
% Use some java magic to enable programmatic mouse clicking
import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
% Get the current mouse location
cp = ax.CurrentPoint;
% Check if mouse is currently inside the axes
if all(prod(axlim - cp,1) < 0)
    % If so, click the mouse and see what it hits
    mouse.mousePress(InputEvent.BUTTON2_MASK);
    mouse.mouseRelease(InputEvent.BUTTON2_MASK);
    % Note that if the mouse was over any of the objects in GOBJ, then FUN
    % just got triggered by the mouse click. Interactivity!
    obj = gco;
else
    % If not, make the current object the axes
    obj = gca;
end
% Reset everything in GOBJ that wasn't just clicked on
for k = 1:length(gobj)
    if obj ~= gobj(k)
        % Copy the saved properties back to the object
        set(gobj(k),gobjprops(k));
    end
end

% Helper to check function inputs
function checkinputs(gobj,fun)
if ~isgraphics(gobj)
    error('First input must be a graphics object (or array of graphics objects)')
end
if ~isa(fun,'function_handle')
    error('Second input must be a function handle')
end
if numel(unique(arrayfun(@class,gobj,'Uniform',false))) > 1
    error('Graphics objects must all be the same type')
end
