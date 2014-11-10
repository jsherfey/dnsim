function dexplore()
%DEXPLORE Start Database Explorer.
% DEXPLORE starts Database Explorer which is an interactive tool that
% allows you to:
%   * Create and Configure JDBC and ODBC data sources
%   * Establish multiple connections to databases
%   * Select tables and columns of interest
%   * Fine-tune selection using SQL query criteria
%   * Preview selected data
%   * Import selected data into MATLAB workspace
%   * Save generated SQL queries
%   * Generate MATLAB code

%   Copyright 1984-2012 The MathWorks, Inc.

a = com.mathworks.toolbox.database.gui.DataAccess;
com.mathworks.toolbox.database.gui.DatabaseToolClient.open(a)
end