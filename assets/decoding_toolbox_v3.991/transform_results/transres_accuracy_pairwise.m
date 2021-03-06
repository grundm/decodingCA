% function output = transres_accuracy_pairwise(decoding_out, chancelevel, varargin)
%
% For more than two classes, rather than getting the mean multiclass
% accuracy across all classes (i.e. chance = 1/n_label), report the mean
% accuracy of all pairwise comparisons (i.e. chance = 1/2).
%
% This code runs faster if all labels are in the same order in all decoding
% steps (e.g. runs).
%
% To use this transformation, use
%
%   cfg.results.output = {'accuracy_pairwise'}
%
% Martin Hebart 2016-03-09
%
% See also transres_accuracy_matrix transres_confusion_matrix

% TODO: allow using subset of accuracy matrix

function output = transres_accuracy_pairwise(decoding_out, chancelevel, varargin)

% A more general form of this code would be to allow using only a subset
% of the matrix in each iteration (e.g. have only some test labels). This
% is not as easy as it may sound. The most elegant solution would probably
% be to create an accuracy matrix of size n_label x n_label x n_step and in
% each iteration use NaNs for the missing values, and average across the
% matrices using our own version of nanmean.
%
% In addition, we would have to use a different M matrix for each run
% (which should not add much computational overhead since M is a persistent
% variable anyway (same applies to occurrence and keepind)
%
% We would also have to be able to relate the original labels to the
% subindex of the labels that we have in a current iteration.

persistent M occurrence keepind

n_step = length(decoding_out);
all_labels = uniqueq(vertcat(decoding_out.true_labels));
n_label = size(all_labels,1);

if size(keepind,1) ~= n_label % if this is the first iteration or there was any change
    
    % we will run a check if all training labels in all runs are the same and have the same identity and count (not necessarily order) as the test labels
    test_labels = decoding_out(1).true_labels;
    if ~isequal(all_labels,uniqueq(test_labels))
        error('Some runs have different labels than others. transres_accuracy_matrix cannot deal with this case yet (sorry, it''s really difficult to code, see code for a detailed description). Please set up a design that does all pairwise classifications and use output sensitivity and specificity.')
    end
    prev = sort(decoding_out(1).model.Label);
    for i_step = 2:length(decoding_out)
        s = sort(decoding_out(i_step).model.Label);
        test_labels = decoding_out(i_step).true_labels;
        if (length(prev) ~= length(s)) || any(prev ~= s) || (n_label == length(s) && any(all_labels ~= s))
            error('Number and/or identity of training labels and/or test labels is not the same across all steps. Unfortunately transres_accuracy_matrix cannot deal with this case yet.  Please set up a design that does all pairwise classifications and use output sensitivity and specificity.')
        end
        if ~isequal(all_labels,uniqueq(test_labels))
            error('Some runs have different labels than others. transres_accuracy_matrix cannot deal with this case yet (sorry, it''s really difficult to code, see code for a detailed description). Please set up a design that does all pairwise classifications and use output sensitivity and specificity.')
        end
        prev = s;
    end
    
    % For speeding everything up, we will use a matrix that we define here that
    % extracts accuracies from the multiclass classification decision values
    M = zeros(n_label,n_label*(n_label-1)/2); % init
    
    % we just need the position of 1, 2, etc. in the lower diagonal matrix,
    % with one row where each of them appears
    [x,y] = meshgrid(1:n_label);
    % pick lower diagonal
    keepind = tril(true(n_label),-1);
    ind = [x(keepind) y(keepind)];
    
    % Now we set each column to 1 where there is the respective number in the index
    for i = 1:n_label
        M(i,ind(:,1)==i) = 1;
        M(i,ind(:,2)==i) = -1;
    end
    
    % to get an idea what this is you can also figure, imagesc(M) and inspect each row
    occurrence = logical(M); % we need this for indexing
    
end

% loop over all cross-validation iterations
acc = zeros(n_step,1);
for i_step = 1:n_step
    
    test_labels = decoding_out(i_step).true_labels;
    
    % get the unique labels and their order for the model
    ulabel = decoding_out(i_step).model.Label;
    % get the decision values
    dv  = decoding_out(i_step).decision_values;
    
    if isequal(all_labels(:),test_labels(:)) % each label occurs only once and in the correct order
        acc(i_step) = mean((sum(dv.*M>0)./sum(occurrence)));
    else
        % get the index of occurrence of all instances
        [~,idx] = ismember(test_labels,ulabel);
        
        % This step calculates all accuracies in the matrix by multiplying
        % the DVs with a sign matrix which will make all correct DVs
        % positive, all incorrect ones negative and will set all irrelevant
        % ones to 0; it will then look what percentage was positive.
        % It respects the order of occurrence of each label and will
        % rearrange the matrix M accordingly (or increase its size if
        % there are multiple occurrences of each)
        acc(i_step) = mean(sum(dv.*M(idx,:)>0)./sum(occurrence(idx,:)));
        
    end
    
end

output = 100*sum(acc)/n_step; % get mean accuracy by dividing sum by number of occurrences and arrange in right format