function enableLog(fid)
% if called, odefun will inform about partial elapsed time at regular periods of the simulation
fprintf(fid,'  if any(k == enableLog)\n');
fprintf(fid,'    elapsedTime = toc(tstart);\n');
fprintf(fid,'    elapsedTimeMinutes = floor(elapsedTime/60);\n');
fprintf(fid,'    elapsedTimeSeconds = rem(elapsedTime,60);\n');
fprintf(fid,'    if elapsedTimeMinutes\n');
logMS = 'Processed %g of %g ms (elapsed time: %g m %.3f s)\n';
logS = 'Processed %g of %g ms (elapsed time: %.3f s)\n';
fprintf(fid,'        fprintf(''%s'',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);\n',logMS);
fprintf(fid,'    else\n');
fprintf(fid,'        fprintf(''%s'',T(k),T(end),elapsedTimeSeconds);\n',logS);
fprintf(fid,'    end\n');
fprintf(fid,'  end\n');