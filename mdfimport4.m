function [save_file,success,message]=mdfimport4(varargin)
%  Import MDF Data to MAT file
%   [file,success,message]=mdfimport4(input_file,save_file/save_path,overwrite,structured_output,recursive)
%
%   The function outputs the full path of the exported file, a 0 or 1 if
%   failed or passed, respectively. And a message on why the script failed.
%
%   If a filename is specified then it is saved as the specified save file.
%   If a path is specified then the file will be saved as 'input_file'.mat.
%   If no path is specified then the file is saved in the current working
%   directory.
%
%   'overwrite'=true [default: false] and the output file already exists the current
%   file will be deleted and over written.
%
%   'structured_output'=true [default: false], then the output files
%   are placed in the output folder structured the same way that they are
%   in the input folder, relative to the input/output bases. Otherwise all
%   the files will be put explicitly in the output directory. Only works if
%   the input_file is a directory of files.
%
%   Example:
%       Input MDFs:
%           C:\test cell 1\mdf1.mdf
%           C:\test cell 1\mdf2.mdf
%           C:\test cell 2\mdf3.mdf
%           C:\mdf4.mdf
%
%       structured_output:  false
%             mdfimport4('C:','D:',true,false);
%                   D:\mdf1.mdf
%                   D:\mdf2.mdf
%                   D:\mdf3.mdf
%                   D:\mdf4.mdf
%
%       structured_output:  true
%             mdfimport4('C:','D:',true,true);
%                   D:\test cell 1\mdf1.mdf
%                   D:\test cell 1\mdf2.mdf
%                   D:\test cell 2\mdf3.mdf
%                   D:\mdf4.mdf
%
%   'recursive'= true. [default: true if structured_output=true, false otherwise], will recurse through all
%   subdirectories to look for MDFs. Otherwise it will only parse files in
%   the current directory.
%
%   This file uses the program 'CallConverter.exe' installed with all
%   CANape releases to convert files to MAT format.

% Setup generic fail messages.
save_file=[];success=0;message='unknown failure';
% Find the converter.
find_converter;
% Sanity check number of input and output arguments
error(nargchk(0, 6, nargin, 'struct'));
error(nargoutchk(0, 3, nargout, 'struct'));
% If no argument is pressed, or the first argument is blank.
if nargin<1||isempty(varargin{1})
    [input_file,s,m]=file_select;
    if s==0
        message=m;
        return;
    end
else
    input_file=abspath(varargin{1});
end
% If no second argument is given or is blank, ask where to save fives.
if (nargin<2 || isempty(varargin{2}))
    save_as=uigetdir(pwd, 'Pick an Output Directory: Press cancel for currect directory.');
    if save_as==0
        save_as=pwd;
    end
else
    save_as=abspath(varargin{2});
end
% Set overwrite to false. Makes the user explicitly request a file
% overwrite
if nargin<3 || isempty(varargin{3}) || ~varargin{3}
    overwrite=false;
else
    overwrite=logical(varargin{3});
end
% Determine if the output should be structured
if nargin<4||isempty(varargin{4})
    structured_output=false;
else
    structured_output=logical(varargin{4});
end
% If the output is structured, then this argument sets the base folder.
if nargin<5||isempty(varargin{5})
    recursive=structured_output;
else
    recursive=logical(varargin{5});
end
% If the output is structured, then this argument sets the base folder.
if nargin<6||isempty(varargin{6})
    base_folder='';
else
    base_folder=varargin{6};
end

% If the 'input file' is actually a directory.
if isdir(input_file)
    base_folder=abspath(input_file);
    % Append trailing \ if it does not exist
    if ~strcmp(base_folder(end),'\')
        base_folder=[base_folder '\'];
    end
    % Get a list of files with mdf extension.
    if recursive
        dos_cmd=sprintf('dir /b /s "%s\\*.mdf"',base_folder(1:end-1));
    else
        dos_cmd=sprintf('dir /b "%s\\*.mdf"',base_folder(1:end-1));
    end
%     disp(dos_cmd);
    [s,files]=dos(dos_cmd);
    if s
        error('dos command failed:\n\t%s',dos_cmd);
    end
    files=strread(files,'%s','delimiter',char(10));
    if strcmp('File Not Found',files{1})
        s=1;
        m='No files found';
        return;
    end
    % Process each file
    files=reshape(files,1,numel(files));
    for file=files
        if recursive
            file=file{1};
        else
            file=fullfile(base_folder,file{1});
        end
        % Recursively call the script.
        [t,~,m]=mdfimport4(file,save_as,overwrite,structured_output,recursive,base_folder);
        % Display results
        disp([m ' ' t]);
    end
    return
    % If the input file does not exist, give error and return.
elseif ~exist(input_file,'file')
    % If file does not exist, error out.
    message=['Input file ' input_file ' does not exist'];
    return;
end
% Process data.
[~,~,ext] = fileparts(input_file);
if ~(strcmpi(ext,'.mdf')||strcmpi(ext,'.dat')||strcmpi(ext,'.xlg'))
    message=['Invalid extension:' ext];
    return;
end
% If the "save_file" is actually a save directory
if isdir(save_as)
    % Check to see if there is a trailing \, if not add one
    if ~strcmp(save_as(end),'\')
        save_as=[save_as '\'];
    end
    if (structured_output&&~isempty(base_folder))
        save_as=strrep([fileparts(input_file) '\'],base_folder,save_as);
        if (~exist(save_as))
            mkdir(save_as);
        end
    end
    % Create the output file's name based on the input file
    [~, fname, ext] = fileparts(input_file);
    save_file = fullfile(save_as,[fname ext '.mat']);
else
    % If the save file does not end in .mat, create a warning, but continue
    [~, ~, ext] = fileparts(save_as);
    if ~strcmp(ext,'.mat')
        warning('Save file does not have .mat extension.');
    end
    save_file = save_as;
end
% If the save file already exists...
if exist(save_file,'file')
    % If 'overwrite' is enabled.
    if overwrite
        % Try to delete file
        try
            delete(save_file);
            % Else throw an error and return
        catch
            message=error(['Failure deleting: ' save_file]);
            return;
        end
    else
        % Otherwise, return
        save_file=input_file;
        success=1;
        message='File already proccesed.';
        return;
    end
end
% Check if the file is too small
% fd=dir(input_file);
% if (fd.bytes<1024)
%     save_file=input_file;
%     success=0;
%     message='File too small <1024 bytes.';
%     warning(message);
%     return;
% end
% Get the file converter.
converter=getpref(mfilename,'CallConverter');
ini=fullfile(tempdir,'CANAPE.INI');
if ~exist(ini,'file')
    createINI;
end
% Create DOS Command
dos_cmd=sprintf('"%s" -C:Matconv.dll -IF:"%s" "%s" "%s"',converter,ini,input_file,save_file);
% Execute DOS Command.
[status,result]=dos(dos_cmd);
% disp(dos_cmd);
success=1;
message='';
if size(regexp(result,'Cannot open input file'),1)
    message='Cannot open input file';
    return;
end
% If the output file doesn't exist, throw an error
if exist(save_file,'file')~=2
    message='Save file not correctly converted, unknown error';
    warning(message);
    return;
end
%%
success=1;
message='Completed.';
return;
end

function [input_file,s,m]=file_select
input_file=0;s=0;m='';
try
    % Ask if the user wants to process a single file or a folder
    ButtonName = questdlg('Process a single file or a folder?', ...
        'Process Question', ...
        'File', 'Folder', 'Folder');
    % Switch...
    switch ButtonName,
        % If the user has selected a file
        case 'File',
            % Prompt the user for the file
            [filename, pathname] = uigetfile( ...
                {'*.mdf;*.dat', 'All MDF Files (*.mdf, *.dat)'; ...
                '*.*',                   'All Files (*.*)'}, ...
                'Pick a file to convert');
            % If they press cancel, return
            if filename==0
                warning('mdfimport4:CANCELED','Action canceled.');
                m='Action Canceled';
                return;
            end
            % Else create the input file based on the result of the dialog
            input_file=fullfile(pathname,filename);
        case 'Folder',
            % Prompt the user for the folder
            pathname = uigetdir('Pick a file to convert');
            % If they press cancel, return
            if pathname==0
                warning('mdfimport4:CANCELED','Action canceled.');
                m='Action Canceled';
                return;
            else
                input_file=pathname;
            end
    end
    s=1;
    m='Converted';
catch
    input_file='';
    s=0;
end
end
%==============================================================================
function absolutepath=abspath(partialpath)
% parse partial path into path parts
[pathname filename ext] = fileparts(partialpath);
% no path qualification is present in partial path; assume parent is pwd, except
% when path string starts with '~' or is identical to '~'.
if isempty(pathname) && isempty(strmatch('~',partialpath))
    Directory = pwd;
elseif isempty(regexp(partialpath,'(.:|\\\\)', 'once' )) && ...
        isempty(strmatch('/',partialpath)) && ...
        isempty(strmatch('~',partialpath));
    % path did not start with any of drive name, UNC path or '~'.
    Directory = [pwd,filesep,pathname];
else
    % path content present in partial path; assume relative to current directory,
    % or absolute.
    Directory = pathname;
end

% construct absulute filename
absolutepath = fullfile(Directory,[filename,ext]);
%--------------------------------------------------------------------------
end

function ini=createINI
fclose('all');
ini=fullfile(tempdir,'CANape.INI');
fid=fopen(ini,'w');
fprintf(fid,['[MDF2MAT]\n' ...
    'OldMode=0\n' ...
    'LongSignalNames=2\n' ...
    'PhysFormat=1\n' ...
    'MatlabFormat=1\n' ...
    'Compression=1\n' ...
    'TimeEachSignal=1\n' ...
    'PrefixM=1\n' ...
    'ReplaceDot=1\n' ...
    'ExtendedNames=0\n' ...
    'TimeGridStep=1\n' ...
    'TimeGrid=0\n' ...
    'Interpolation=1\n' ...
    'StartTimeZero=1\n' ...
    'OnStartSignals=0\n' ...
    'DisplayName=0']);
fclose(fid);fclose('all');
end

function find_converter
% Attempt to find the converter in the default vector folder
paths.CallConverter={
    'C:\Program Files (x86)\Vector\CANape\10.0\Exec\CallConverter.exe', ...
    'C:\Program Files (x86)\Vector\CANape\9.0\Exec\CallConverter.exe', ...
    'C:\Program Files (x86)\Vector\CANape\8.0\Exec\CallConverter.exe', ...
    'C:\Program Files (x86)\Vector\CANape\7.0\Exec\CallConverter.exe', ...
    'C:\Program Files (x86)\Vector\CANape\6.5\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector\CANape\10.0\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector\CANape\9.0\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector\CANape\8.0\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector\CANape\7.0\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector\CANape\6.5\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector CANape 7.0\Exec\CallConverter.exe', ...
    'C:\Program Files\Vector CANape 6.5\Exec\CallConverter.exe'};
% Required programs
progs=fieldnames(paths);
progs=reshape(progs,1,numel(progs));
script=mfilename;
for prog=progs
    prog=prog{1};
    if ~ispref(script,prog) || ... % if the preference is not set.
            ~exist(getpref(script,prog),'file') % or the old path no longer exists
        found=false;
        for path=paths.(prog)
            if exist(path{1},'file')
                setpref(script,prog,path{1});
                [~,n,e]=fileparts(path{1});
                fprintf('%s%s found and preferences saved (%s)\n',n,e,path{1});
                found=true;
                break;
            end
        end
        if ~found
            if exist('C:\Program Files (x86)\','dir')
                lwd=cd('C:\Program Files (x86)\');
            elseif exist('C:\Program Files','dir')
                lwd=cd('C:\Program Files\');
            else
                lwd=pwd;
            end
            [~,n,e]=fileparts(path{1});
            n=sprintf('%s%s',n,e);
            [filename, pathname] = uigetfile(n, sprintf('%s not automatically found. Please select it:',n));
            if filename==0
                error('mdfimport4:canceled','User canceled executable selection');
                return;
            end
            cd(lwd);
            setpref(script,prog,fullfile(pathname,filename));
        end
    end
end
end