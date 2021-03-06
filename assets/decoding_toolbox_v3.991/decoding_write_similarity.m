function decoding_write_similarity(resname,contrasts,overwrite)

% This function can be used to write similarity searchlight results that
% have been stored in a .mat file of results generated by The Decoding
% Toolbox. All results are written separately to images starting from
% beta_0001. In addition, contrasts between multiple similarity results can
% be specified and passed separately and will be written to con_0001, etc.
%
% INPUT:
%   resname: full path to .mat file containing the results. The *cfg.mat
%       should also be in the path that contains resname.
%   contrasts: row vector of contrast that should be written. If more than
%       one contrast should be used, pass each contrast in a separate cell
%       array.
%   overwrite (optional): Should existing betas and contrasts be
%       overwritten? If betas/contrasts already exist, an error is thrown.
%       (default for overwrite: 0)
%   
% Example call:
% respath = 'temp_zco_runwise_full7_m4';
% resname = 'res_rsa_beta';
% cfg = config_subjects;
% for i_sub = cfg.subject_indices
%   fullrespath = fullfile(cfg.sub(i_sub).dir,'results','similarity',respath);
%   fullresname = fullfile(fullrespath,[resname '.mat']);
%   decoding_write_similarity(fullresname,contrasts);
% end

if ~exist('overwrite','var')
    overwrite = 0;
end

[respath,rname,rext] = fileparts(resname);
splitind = strfind(rname,'_');
if ~isempty(splitind) && splitind(1) ~= length(rname)
    measure_name = rname(splitind+1:end);
else
    measure_name = rname;
end

% get XXX_cfg.mat
fnames = dir(fullfile(respath,'*cfg.mat'));
fnames = char(fnames.name);
n = size(fnames,1);
if n > 1
    % if more than one entry, pick the one more similar to resname
    match = false(n,1);
    for i_name = 1:n
        currname = strtrim(fnames(i_name,:));
        splitind = strfind(currname,'_');
        if isempty(splitind)
            continue
        end
        if strcmp(currname(1:splitind),rname(1:splitind))
            match(i_name) = 1;
        end
    end
    if ~any(match) || sum(match)>1
        error('Could not uniquely specify which cfg.mat to use in %s. Please remove one from that path or rename it.',respath)
    end
else
    match = true;
end    

cfgname = fullfile(respath,fnames(match,:));

load(cfgname)
load(resname)

if ~isfield(results,measure_name)
    disp('Example file name for results ''rsa_beta'': res_rsa_beta.mat where ''res'' could be any string without ''_''.')
    error('Cannot extract type of analysis used from results file name.')
end

hdr = read_header(cfg.software,cfg.files.name{1});

[trash,trash2,fext] = fileparts(hdr.fname);

resvol = zeros(results.datainfo.dim);
output = [results.(measure_name).output{:}];

% First check if betas exist in results path
fd = dir(respath);
fn = num2cell(char(fd(:).name),2);
doesexist = ~isempty(cell2mat(regexp(fn,'.*beta_.[0-9].*\.(img|nii)')));
if doesexist
    if overwrite
        warning('Overwriting previously created beta/con images.')
        rmlist = regexp(fn,'.*(beta|con)_.[0-9].*\.(img|nii|hdr)','match');
        for i_rm = 1:length(rmlist)
            if ~isempty(rmlist{i_rm})
                delete(fullfile(respath,rmlist{i_rm}{1}))
            end
        end
    else
        error('Betas already exist in %s. set overwrite = 1 if you want to overwrite this result.',respath)
    end
end

% Then write
dispv(1,'Writing betas to %s',respath)
for i_beta = 1:size(output,1);
    hdr.fname = sprintf('%s%s%s_beta_%04i%s',respath,filesep,rname,i_beta,fext);
    resvol(results.mask_index) = output(i_beta,:);
    write_image(cfg.software,hdr,resvol);
end

if exist('contrasts','var') && ~isempty('contrasts')
    dispv(1,'Writing requested contrasts...')
    if isnumeric(contrasts)
        n_con = 1;
        contrasts = {contrasts};
    else
        n_con = length(contrasts);
    end
    for i_con = 1:n_con
        hdr.fname = sprintf('%s%s%s_con_%04i%s',respath,filesep,rname,i_con,fext);
        resvol(results.mask_index) = contrasts{i_con}*output;
        write_image(cfg.software,hdr,resvol);
    end
end