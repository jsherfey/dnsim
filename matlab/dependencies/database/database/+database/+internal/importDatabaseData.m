function importDatabaseData(dataFetched, batchCount, rowCount, numberOfColumns,columnNames, columnTypes, varNameIn, dataReturnFormat)
%database.internal.importDatabaseData Undocumented internal function

% Function imports data from a Java vector into a MATLAB variable, the data
% type of which is decided as per user preferences

%   Copyright 2012 The MathWorks, Inc.

fet = com.mathworks.toolbox.database.fetchTheData;

%Get Batch size
databasePrefs = javaObjectEDT('com.mathworks.toolbox.database.databasePrefs');
batchSize = double(javaMethodEDT('getImportBatchSize', databasePrefs));

if(size(dataFetched)== 0 || numberOfColumns == 0)
    evalin('base' ,['if ~exist(''' varNameIn ''', ''var'') ' varNameIn ' = ''No Data''; end']);
    return;
end

numberOfRows = size(dataFetched)/numberOfColumns;

switch lower(dataReturnFormat)
    
    case 'cellarray'
        
        %Convert java.util.vector to cell array
        importedData = system_dependent(44,dataFetched,numberOfRows)';
        
        %initialize base variable
        if(batchCount == 0)
            evalin('base' ,[ varNameIn ' = cell(' num2str(rowCount) ',' num2str(numberOfColumns) ');']);
        end
        
        %send imported data to base
        assignin('base', 'importedData', importedData);
        
        %Assign data to base variable
        incSize = min(batchSize, size(importedData, 1));
        startRow = batchSize*batchCount + 1;
        endRow = startRow + incSize - 1;
        evalin('base', ['' varNameIn '(' num2str(startRow) ':' num2str(endRow) ', :) = importedData;']);
        evalin('base', 'clear importedData;');
        
        
    case 'numeric'
        
        %Check if null number setting is incorrect
        if isempty(str2num(javaMethodEDT('getNullNumberRead', databasePrefs)))
            if ~(javaMethodEDT('getExceptionThrown', 'com.mathworks.toolbox.database.gui.DataImporter'))
                throw (MException(message('database:cursor:invalidNullNumber')));
            else
                return;
            end
        end
        
        %java method VectorToDouble converts java.util.vector to matrix of doubles
        importedData = fet.VectorToDouble(dataFetched,numberOfRows,numberOfColumns, str2num(javaMethodEDT('getNullNumberRead', databasePrefs)));
        
        %initialize base variable
        if(batchCount == 0)
            evalin('base' ,[ varNameIn ' = zeros(' num2str(rowCount) ',' num2str(numberOfColumns) ');']);
        end
        
        %send imported data to base
        assignin('base', 'importedData', importedData);
        
        %Assign data to base variable
        incSize = min(batchSize, size(importedData, 1));
        startRow = batchSize*batchCount + 1;
        endRow = startRow + incSize - 1;
        evalin('base', ['' varNameIn '(' num2str(startRow) ':' num2str(endRow) ', :) = importedData;']);
        evalin('base', 'clear importedData;');
        
        
    case {'structure','dataset','table'}
        
        
        
        nc = length(columnNames);
        fnames = cell(nc,1);
        for i = 1:nc
            colName = char(columnNames{i});
            if any(strcmp(colName,fnames))
                fnames{i} = [colName '_' num2str(i)];
            else
                fnames{i} = colName;
            end
        end
        
        %Initialize structure
        for i = 1:length(columnTypes)
            
            %Insitialize structure in base workspace
            if(batchCount == 0 && i==1)
                evalin('base' ,[varNameIn ' = struct;' ]);
            end
            
            colName = genvarname(fnames{i});
            
            switch columnTypes(i)
                
                case {-6,-5,2,3,4,5,6,7,8}
                    
                    %Check if null number setting is incorrect
                    if isempty(str2num(javaMethodEDT('getNullNumberRead', databasePrefs)))
                        if ~(javaMethodEDT('getExceptionThrown', 'com.mathworks.toolbox.database.gui.DataImporter'))
                            evalin('base' ,['clear ' varNameIn]);
                            throw (MException(message('database:cursor:invalidNullNumber')));       
                        else
                            return;
                        end
                    end
                    
                    %Numerics
                    importedData.(colName)  = fet.VectorToNumber(dataFetched,numberOfRows,numberOfColumns,str2num(javaMethodEDT('getNullNumberRead', databasePrefs)), i-1);
                    
                    %Initialize fields of structure in base workspace
                    evalin('base' ,['if ~isfield(' varNameIn ', ''' colName ''') ' varNameIn '.' colName '= zeros(' num2str(rowCount) ',1); end']);
                    
                otherwise
                    
                    %Strings or other data types, create vector of strings and convert to cell array
                    importedData.(colName) = system_dependent(44,fet.VectortoStringVector(dataFetched,numberOfRows,numberOfColumns,i-1, javaMethodEDT('getNullStringRead', databasePrefs)), numberOfRows)';
                    
                    %Initialize fields of structure in base workspace
                    evalin('base' ,['if ~isfield(' varNameIn ', ''' colName ''') ' varNameIn '.' colName '= cell(' num2str(rowCount) ',1); end']);
                    
            end
            
            %send imported data to base
            assignin('base', 'importedData', importedData.(colName));
            
            %Assign data to base variable
            incSize = min(batchSize, size(importedData.(colName), 1));
            startRow = batchSize*batchCount + 1;
            endRow = startRow + incSize - 1;
            evalin('base', ['' varNameIn '.' colName '(' num2str(startRow) ':' num2str(endRow) ', :) = importedData;']);
            evalin('base', 'clear importedData;');
            
        end
        
        %Convert only after import is complete
        if batchCount == ceil(rowCount/batchSize)-1
          switch lower(dataReturnFormat)
            case 'dataset'
              evalin('base', [varNameIn ' = dataset(' varNameIn ');']);
            case 'table'
              evalin('base', [varNameIn ' = struct2table(' varNameIn ');']);
          end
              
        end
        
        
end

end


