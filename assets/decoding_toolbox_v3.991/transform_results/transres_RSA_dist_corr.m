function output = transres_RSA_dist_corr(decoding_out,chancelevel,cfg,data)

% function output = transres_RSA_dist_corr(decoding_out,chancelevel,cfg,data)
% 
% Calculates the correlation between all datapoints of the full datamatrix.
%

% 2013 Martin H.

warningv('TRANSRES_RSA_DIST_CORR:DEPREC',...
    ['The use of this function is deprecated and it will be removed ',...
     'in future versions of the toolbox. Please use ',...
     'cfg.decoding.software = ''similarity'', ',...
     'cfg.decoding.train.classification.model_parameters = ''cor'', ',...
     'and cfg.results.output = ''other'' to return correlations and ',...
     'take 1-results.similarity.output as the result.'])
output = {1-correlmat(data')};