function hdlg = myerrordlg(s,ti,varargin)

if nargin < 1,
  s = '';
end
if nargin < 2,
  ti = '';
end

if ~iscell(s),
  s = {s};
end

screensz = get(0,'ScreenSize');
c = screensz(3)/2;
m = screensz(4)/2;
w = min(500,screensz(3)-50);
h = min(500,screensz(4)-50);
pos = [c-w/2,m-h/2,w,h];
hdlg = dialog('Units','pixels','Position',pos,...
  'Name',ti,'WindowStyle','normal',varargin{:});

border = 20;
buttonspace = 40;
c1 = w/2;
t1 = h - border;
w1 = w - border*2;
h1 = h - border*2 - buttonspace;
pos1 = [c1-w1/2,t1-h1,w1,h1];
htxt = uicontrol('Style','edit','Parent',hdlg,'Units','pixels',...
  'Position',pos1,'HorizontalAlignment','left','String','test','Min',0,'Max',50);
[s,pos1] = textwrap(htxt,s,80);
w1 = pos1(3);
h1 = pos1(4);
w = w1 + 2*border;
h = h1 + 2*border + buttonspace;
pos = [c-w/2,m-h/2,w,h];
set(hdlg,'Position',pos);
set(htxt,'Position',pos1,'String',s);

w2 = 60;
h2 = 23;
margin = 5;
c2 = w/2 - w2/2 - margin/2;
b2 = border;
pos2 = [c2-w2/2,b2,w2,h2];
uicontrol('Style','pushbutton','Parent',hdlg,'Position',pos2,...
  'String','OK','Callback',@(hObject,event) delete(get(hObject,'Parent')));

c3 = w/2 + w2/2 + margin/2;
b2 = border;
pos3 = [c3-w2/2,b2,w2,h2];

if iscell(s),
  s = sprintf('%s\n',s{:});
end

uicontrol('Parent',hdlg,'Units','pixels',...
  'Position',pos3,'String','Copy',...
  'Callback',@(hObject,event) clipboard('copy',s));
