%Util Functions class
classdef DatabaseUtils
    methods(Static)
                
        function OK = tablenameCheck(tablename)
            
            if(~(ischar(tablename) && ~isempty(tablename)))
                error(message('database:fastinsert:inputTableError'))
            else
                OK = true;
                
            end
        end
        
        function OK = fieldnamesCheck(fieldnames)
            
            if(~(iscell(fieldnames) && ~isempty(fieldnames) && (size(fieldnames, 1) == 1 || size(fieldnames, 2) == 1) && all(cellfun(@ischar, fieldnames)) && ~any(cellfun(@isempty, fieldnames))))
                error(message('database:fastinsert:inputFieldsError'))
            else
                OK = true;
                
            end
        end
        
        function OK = insertDataCheck(data)
            
            expectedClassOfData = {'cell', 'double', 'struct', 'dataset', 'table'};
            
            if(~any(strcmp(class(data),expectedClassOfData)))
                error(message('database:fastinsert:inputDataError'))
            else
                OK = true;
                
            end
        end
        
        function outData = validateStruct(data)
            
            outData = data;
            
            %Check if struct is a scalar
            if(~isscalar(data))
                error(message('database:fastinsert:invalidStructFormat'));
            end
            
            sflds = fieldnames(data);
            numRows = 0;
            
            for i = 1:length(sflds)
                
                %Get each field value
                fielddata = data.(sflds{i});
                
                if(ischar(fielddata))
                    fielddata = {fielddata};
                    outData.(sflds{i}) = fielddata;
                end
                
                if(iscell(fielddata))
                    %Bunch of checks to perform
                    
                    %1. Check dimensions of cell
                    cellsize = size(fielddata);
                    
                    if(cellsize(2) > 1)
                        error(message('database:fastinsert:invalidStructFormat'))
                    end
                    
                    %2. Check for cell inside of cells
                    celldata = fielddata{1};
                    
                    if(iscell(celldata))
                        error(message('database:fastinsert:invalidStructFormat'))
                    end
                    
                    %3. Check num rows
                    if(i > 1 && numRows ~= cellsize(1))
                        error(message('database:fastinsert:invalidStructFormat'))
                    end
                    
                    numRows = cellsize(1);
                    
                    %4. If celldata is a double convert it to numeric
                    %matrix
                    if(isa(celldata, 'double'))
                        fielddata = cell2mat(fielddata);
                        outData.(sflds{i}) = fielddata;
                    end
                end
                
                if(isa(fielddata, 'double'))
                    cellsize = size(fielddata);
                    
                    if(cellsize(2) > 1)
                        error(message('database:fastinsert:invalidStructFormat'))
                    end
                    
                    if(i > 1 && numRows ~= cellsize(1))
                        error(message('database:fastinsert:invalidStructFormat'))
                    end
                    
                    numRows = cellsize(1);
                end
            end
            
            
        end
    end
end
