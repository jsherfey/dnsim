function qbhelp(hflag)
%QBHELP Visual Query Builder help string.
%   QBHELP(HFLAG) returns the Visual Query Builder help string in a help window.
%   HFLAG determines which section of the Visual Query Builder help 
%   string to display.   HFLAG can be WHERE, GROUP BY, HAVING, ORDER BY,
%   DISPLAY DATA, DISPLAY CHART, or ALL.

%   Copyright 1984-2008 The MathWorks, Inc.

if nargin == 0
  hflag = 'ALL';
end

%Determine topic_id input
switch hflag
  
  case 'WHERE'
    topic_id = 'vqb_where';
    
  case 'GROUP BY'
    topic_id = 'vqb_groupby';
    
  case 'HAVING'
    topic_id = 'vqb_having';
    
  case 'ORDER BY'
    topic_id = 'vqb_orderby';
    
  case {'ALL','Visual Query Builder'}
    topic_id = 'dbtb_vqb';
    
	case 'TOOLBOX'
		topic_id = 'dbtb_gs';
		
  case 'DISPLAY CHART'
    topic_id = 'vqb_charting';
    
  case 'Subquery'
    topic_id = 'vqb_subquery';
    
  case 'Preferences'
    topic_id = 'vqb_prefs';
    
  case 'Configure DataSource'
    topic_id = 'db_confds';
   
	case 'AboutDialog'
        v = ver('database');
        verstr = v.Version;
        [yr,~] = datevec(now);
		aboutstring = {'The Database Toolbox for use with MATLAB(r)';...
				           ' ';...
									 ['Version ' verstr];...
									 ' ';...
									 ['Copyright 1984-' num2str(yr) ' The MathWorks, Inc.']};
    msgbox(aboutstring,'About Database Toolbox')
		return
		
  otherwise
    topic_id = 'vqb_dialogbox';
   
end  
  
%Open help window
helpview([docroot '\toolbox\database\database.map'],topic_id)
