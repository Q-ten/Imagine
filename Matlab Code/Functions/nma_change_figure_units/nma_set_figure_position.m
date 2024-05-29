function nma_set_figure_position(the_handle,x,y,w,h)
%utility function, called to create a figure in middle of window

%
%by Nasser M. Abbasi
%

sz    = get(0,'ScreenSize');
wid   = sz(3);
hight = sz(4);
set(the_handle,'Units','pixels');
set(the_handle,'Position',[x*wid y*hight w*wid h*hight]);

end

