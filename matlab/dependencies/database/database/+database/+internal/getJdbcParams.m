function configParams = getJdbcParams(datasource)
%database.internal.getJdbcParams undocumented internal function

jdbcFile = setdbprefs('JDBCDataSourceFile');
configParams = [];

if(~exist(jdbcFile, 'file'))
    return;
end

load(jdbcFile);

if(~exist('srcs', 'var'))
    return;
end

foundSource =  strcmp(datasource,  cellstr(srcs(:, 1)));

if(any(foundSource))
    configParams = srcs(foundSource, :);
end


end