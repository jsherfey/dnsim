function display(d)
%DISPLAY Database Toolbox objects display method.

%   Copyright 1984-2008 The MathWorks, Inc.

tmp = struct(d);   %Extract the structure for display

if ~strcmp(class(d),'dbtbx')  %dbtbx field is a dummy field used for
    tmp = rmfield(tmp,'dbtbx'); %inheritance only, do not display it
end

%If input is an array

if (length(d) > 1)
    s = size(d);
    str = sprintf('%dx',s);
    str(end) = [];
    tmp = sprintf('%s array of %s objects\n', str, class(d));
    %return;
else
    
    %Database connection and cursor objects have properties in displayed information
    if any(strcmp(class(d),{'database','cursor'}))
        flds = fieldnames(tmp);
        for i = 1:length(flds)
            try
                newtmp.(flds{i}) = get(d,flds{i});
            catch exception %#ok
                newtmp.(flds{i}) = tmp.(flds{i});
            end
        end
        
        tmp = newtmp;
        
    end
end

if isequal(get(0,'FormatSpacing'),'compact')  %Display based on formatting
    disp([inputname(1) ' =']);
    disp(tmp)
else
    disp(' ')
    disp([inputname(1) ' =']);
    disp(' ')
    disp(tmp)
end