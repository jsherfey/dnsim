function status = saveJdbcConfig(configParams, action)
%database.internal.saveJdbcConfig undocumented internal function

%Function saves a newly created jdbc data source in Database Exporer
%to a config file.
%
%CONFIGPARAMS is an object array of jdbc connection parameters
%ACTION is an integer which indicates whether the action is add(1) or
%delete(2)
%STATUS indicates the return status

%   Copyright 2012 The MathWorks, Inc.

jdbcFile = setdbprefs('JDBCDataSourceFile');
status = 1; %initialize to failed status

if(exist(jdbcFile, 'file'))
    load(jdbcFile);
end

%Convert to cell array

newJdbcConfig = cell(configParams);

%When action is ADD

if(action == 1)
    
    if(~exist('srcs', 'var'))
        srcs = newJdbcConfig;
    else
        if(size(srcs, 2) ~= 7) %Old style of saving JDBC driver and URL
            oldsrcs = srcs;
            srcs = cell(size(oldsrcs, 1), 7);
            
            srcs(:, 1:size(oldsrcs, 2)) = oldsrcs;
        end
        
        %Check if data source already exists
        foundSource =  strcmp(newJdbcConfig{1,1},  cellstr(srcs(:, 1)));
        
        if(any(foundSource)) %Source exists, ask if user wants to overwrite
            reply = javaMethodEDT('showConfirmDialog', 'com.mathworks.mwswing.MJOptionPane', [], message('database:dexplore:saveError_message').getString(), message('database:dexplore:saveError_title').getString(), com.mathworks.mwswing.MJOptionPane.YES_NO_OPTION);
            
            if(reply ~= 0 ) %NO
                status = 1;
                return;
            else %YES, overwrite
                srcs(foundSource, :) = newJdbcConfig;
            end
            
        else
            srcs = [srcs; newJdbcConfig];
        end
    end
    
    %When action is DELETE
    
elseif(action == 2)
    
    foundSource =  strcmp(newJdbcConfig{1,1},  cellstr(srcs(:, 1)));
    
    if(~any(foundSource)) %Nothing to delete
        javaMethodEDT('showMessageDialog', 'com.mathworks.mwswing.MJOptionPane', [], message('database:dexplore:deleteError_message').getString(), message('database:dexplore:deleteError_title').getString(), com.mathworks.mwswing.MJOptionPane.ERROR_MESSAGE);
        return;
    end
    
    srcs(foundSource, :) = [];
    
else
    error(message('database:dexplore:invalidAction_message'));    
end

save(jdbcFile, 'srcs');
status = 0; %success
end