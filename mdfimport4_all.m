function mdfimport4_all(folder,depth)
%mdfimport4_all  Convert all mdf files in a folder to mat
%   If no folder is given, the current folder is processed
%
%   Example
%   mdfimport4_all;
%   mdfimport4_all('C:\CANape\');
%
%   See also mdfimport4

% Author: Jedediah Frey
% Created: Sep 2008
% Copyright 2008

% If no folder is specified
warning('off','MATLAB:dispatcher:ShadowedMEXExtension');
if nargin<1
    folder=pwd;
end
if nargin<2
    depth=1;
end
% Create a list of files
[files_list,total_files] = file_list(folder,'*.MDF',depth);
% For each files
for i=1:total_files
    % Save The File
    [t,s,m]=mdfimport4(files_list{i},pwd,0);
    % Display that the file was converted
    if s
        disp([m ' ' t]);
    else
        disp(['Failed ' t]);
    end
end
end
