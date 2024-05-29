function gridcolor(fig, ax, majorX, majorY, minorX, minorY)

ax1 = ax;   %# get a handle to first axis

%# create a second transparent axis, same position/extents, same ticks and labels
ax2 = copyobj(ax1,fig);
ax3 = copyobj(ax1,fig);

delete(get(ax2,'Children'));
delete(get(ax3,'Children'));

set(ax2, 'Color','none', 'Box','off','YTickLabel',[],'YTickLabel',[],...
    'XMinorGrid','off','YMinorGrid','off',...
    'GridLineStyle', '-');
if ~isempty(majorX)
    set(ax2, 'XGrid','on', 'XColor', majorX);
else
   set(ax2, 'XGrid', 'off'); 
end
if ~isempty(majorY)
    set(ax2, 'YGrid','on', 'YColor', majorY);
else
   set(ax2, 'YGrid', 'off'); 
end


set(ax3,'Box','off','YTickLabel',[],'YTickLabel',[],...
    'MinorGridLineStyle','-',...
    'XGrid','off','YGrid','off');
if ~isempty(minorX)
    set(ax3, 'XMinorGrid','on', 'XColor', minorX);
else
   set(ax3, 'XMinorGrid', 'off'); 
end
if ~isempty(minorY)
    set(ax3, 'YMinorGrid','on', 'YColor', minorY);
else
   set(ax3, 'YMinorGrid', 'off'); 
end

set(ax1, 'Color','none', 'Box','on')

handles = [ax3; ax2; ax1];
c = get(fig,'Children');
for i=1:length(handles)
    c = c(find(c ~= handles(i)));
end
set(fig,'Children',[c; flipud(handles)]);

linkaxes([ax1 ax2 ax3]);
end

%subplot(211);semilogx([1:4000]);gridcolor('r','g','c','b');
%subplot(212);semilogx(([1:4000]).^-1);gridcolor('r','g','c','b');