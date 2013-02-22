function [save_file,success,message]=mdfimport4(varargin)
%  Import MDF Data to MAT file
%   [file,success,message]=mdfimport4(input_file,save_file/save_path,overwrite,structured_output)
%
%   The function outputs the full path of the exported file, a 0 or 1 if
%   failed or passed, respectively. And a message on why the script failed.
%
%   If a filename is specified then it is saved as the specified save file.
%   If a path is specified then the file will be saved as 'input_file'.mat.
%   If no path is specified then the file is saved in the current working
%   directory.
%
%   If 'overwrite' is true [default: false] and the output file already exists the current
%   file will be deleted and over written. 
%
%   If 'structured_output' is true [default: false], then the output files
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
%   This file uses the program 'CallConverter.exe' installed with all
%   CANape releases to convert files to MAT format.

try
    % Setup generic fail messages.
    save_file=[];success=0;message='Catastrophic Failure';
    % Sanity check number of input and output arguments
    try
        error(nargchk(0, 5, nargin, 'struct'));
        error(nargoutchk(0, 3, nargout, 'struct'));
    catch
        message=descriptiveError('Failure checking IO arguments: ');
        disp(message);
    end
    % If no argument is pressed, or the first argument is blank.
    if nargin<1||isempty(varargin{1})
        [input_file,s,m]=file_select;
        if s==0
            message=m;
        end
    else
        input_file=varargin{1};
    end
    % If no second argument is given or is blank, save to the current working
    % directory
    if (nargin<2 || isempty(varargin{2}))
        save_as=uigetdir(pwd, 'Pick an Output Directory: Press cancel for currect directory.');
        if save_as==0
            save_as=pwd;
        end
    else
        save_as=varargin{2};
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
        base_folder='';
    else
        base_folder=varargin{5};
    end
    
    % If the 'input file' is actually a directory.
    if isdir(input_file)
        base_folder=input_file;
        % Append trailing \ if it does not exist
        if ~strcmp(base_folder(end),'\')
            base_folder=[base_folder '\'];
        end
        % Get a list of files with mdf extension.
        [files,file_number]=file_list(input_file,'.mdf');
        % Process each file
        for i=1:file_number
            % Recursively call the script.
            [t,s,m]=mdfimport4(files{i},save_as,overwrite,structured_output,base_folder);
            % Display results
            disp([m ' ' t]);
        end
        return
        % If the input file does not exist, give error and return.
    elseif ~exist(input_file,'file')
        % If file does not exist, error out.
        message=['Input file ' input_file ' does not exist'];
        return;
    else
        % Get the full valid path.
        [input_file]=validpath(input_file);
    end
    % Process data.
    [pathstr,name,ext] = fileparts(input_file);
    if ~(strcmpi(ext,'.mdf')||strcmpi(ext,'.dat')||strcmpi(ext,'.xlg'))
        message=['Invalid extension:' ext];
        return
    end
catch
    message=descriptiveError('Failure validating input arguments');
    return;
end
% If the "save_file" is actually a save directory
if isdir(save_as)
    % Check to see if there is a trailing \, if not add one
    if ~strcmp(save_as(end),'\')
        save_as=[save_as '\'];
    end
    if (structured_output&&~isempty(base_folder))
        save_as=strrep(fileparts(input_file),base_folder,save_as);
        if (~exist(save_as))
            mkdir(save_as);
        end
    end
    % Create the output file's name based on the input file
    [pathstr, fname, ext] = fileparts(input_file);
    save_file = fullfile(save_as,[fname ext '.mat']);
else
    % If the save file does not end in .mat, create a warning, but continue
    [pathstr, fname, ext, versn] = fileparts(save_as);
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
            message=descriptiveError(['Failure deleting: ' save_file]);
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
fd=dir(input_file);
if (fd.bytes<1024)
    save_file=input_file;
    success=0;
    message='File too small <1024 bytes.';
    warning(message);
    return;
end
% Get the file converter.
if ~ispref('mdfimport4','callconverter')||~exist(getpref('mdfimport4','callconverter'),'file')
    converter=find_converter;
    setpref('mdfimport4','callconverter',converter);
else
    converter=getpref('mdfimport4','callconverter');
end
if ~exist(fullfile(tempdir,'CANAPE.INI'),'file')
    createINI
end
% Create DOS Command
dos_cmd=sprintf('"%s" -C:Matconv.dll -IF:"%s" "%s" "%s"',converter,fullfile(tempdir,'CANAPE.INI'),input_file,save_file);
% Execute DOS Command.
[status,result]=dos(dos_cmd);
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
s=0;m='';
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
    m=descriptiveError;
end
end

function [filename]=validpath(filename,ext0)
% VALIDPATH: builds a full path from a partial path specification
% [filename] = VALIDPATH(filename,ext0)
%
% INPUT PARAMETERS:
% filename: string vector containing a partial path ending in a file or
%           directory name. May contain ..\  or ../ or \\ character sets. If
%           FILENAME contains more than a file name or directory name the
%           current directory will not be prepended to creat a full path.
%           Otherwise, the current directory (pwd) is prepended to create a
%           full path. An exception is on UNIX, when the path starts in the '~'
%           character, then the currently directory is not prepended.
% ext0:     string vector specifying the default extention to be used.
%
% RETURN PARAMETERS:
% filename: string vector containing full path to a file.

%  Copyright 1984-2005 The MathWorks, Inc.
%  $Revision: 1.1.6.8 $
%==============================================================================
%First check for wild cards, since that is not supported.

% break partial path in to file path parts.
[Directory,file,ext]=fileparts(filename);

% add default extension
if isempty(ext) && ~isempty(ext0)
    ext = ext0;
end
% rebuild partial path
file = fullfile(Directory,[file ext]);
% search source file on M path
FileOnPath = which(file);
if isempty(FileOnPath)
    % construct full path to source file
    filename = abspath(file);
    if isempty(dir(filename)) && ~isdir(filename)
        % file does not exist. Terminate importation of file.
        error('MATLAB:xlsread:FileNotFound','File %s not found.',filename);
    end
else filename = FileOnPath;
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

function createINI
fclose('all');
ini=fullfile(tempdir,'CANape.INI');
[fid,m]=fopen(ini,'w');
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

function converter=find_converter
% Attempt to find the converter in the default vector folder
search_folder={'C:\Program Files (x86)\Vector\CANape','C:\Program Files\VECTOR','C:\Program Files\Vector CANape 7.0','C:\Program Files\Vector CANape 6.5','C:\Program Files\'};
for i=1:numel(search_folder)
    if isdir(search_folder{i});
        converters=file_list(search_folder{i},'*.exe',inf,'CallConverter.exe');
        break;
    end
end
% If no file is found, prompt the user to select the correct file.
if numel(converters)==0
    warning('No executable ''CallConverter.exe'' found in selected folder. You may have selected the wrong folder or CANape may be installed in a non-standard location.');
    if isdir('C:\Program Files\VECTOR')
        o=cd('C:\Program Files\VECTOR');
    else
        o=cd('C:\Program Files');
    end
    try
        [filename, pathname] = uigetfile( ...
            {'CallConverter.exe','CallConverter.exe'}, ...
            'Select CallConverter.exe file...', ...
            'MultiSelect', 'off');
        if (filename==0)
            error('CallConverter selection canceled');
        end
        % Use this as the converter
        converter=fullfile(pathname,filename);
    catch
        error('Unknown file selection error.');
    end
    cd(o);
    return;
end
% If there is only one converter, then use that
if numel(converters)==1
    converter=converters{1};
    return;
end
% If there is more than one converter found, then find the 'latest
% version'.
% Zero the versions number.
version=zeros(1,numel(converters));
% For each converter found
for i=1:numel(converters)
    % Run with 'help' and get the results
    [status,result]=dos(['"' converters{i} '" -h']);
    % Regex the results
    n=regexp(result,'V([\d.]+)[\s]*\(([\d]+-[\d]+-[\d]+)\)','tokens');
    % If a result is found
    if numel(n)
        % Convert the release date of the converter to a number.
        version(i)=datenum(n{1}{2});
    end
end
if (max(version))==0
    % Could not determine any version numbers, go with the last version
    % found.
    converter=converters{end};
else
    % Otherwise, the converter to use is the one with the latest release
    % date.
    converter=converters{find(version==max(version),1)};
end
end
