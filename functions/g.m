function h=g(f)
% http://stackoverflow.com/questions/19406551/when-can-i-pass-a-function-handle

x = functions(f);
if ~strcmp(x.type, 'anonymous')
    h = evalin('caller', ['@(varargin)' x.function '(varargin{:})']);
else
    h = f;
end
