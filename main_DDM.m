dbstop if error;
warning('on', 'verbose')
warning('off', 'MATLAB:colon:operandsNotRealScalar');

if ispc
    root = 'L:/';
    subject_id = 'AA181'; %AA181 AA438 AB418 AD074 AA081
    result_dir = [root 'rsmith\lab-members\cgoldman\change_point_detection\fitting_output\test\'];
    DCM.settings.drift_mapping = 'action_prob';
    DCM.settings.bias_mapping = 'action_prob';
    DCM.settings.threshold_mapping = '';
    DCM.field = {'reward_lr','inverse_temp','reward_prior','decision_thresh','bias_mod', 'drift_baseline', 'drift_mod','nondecision_time'};
else
    root = '/media/labs/'
    subject_id = getenv('SUBJECT')
    result_dir = getenv('RESULTS')
    DCM.settings.drift_mapping = cellstr(strsplit(getenv('DRIFT_MAPPING'),","))
    DCM.settings.bias_mapping = cellstr(strsplit(getenv('BIAS_MAPPING'),","))
    DCM.settings.threshold_mapping = cellstr(strsplit(getenv('THRESHOLD_MAPPING'),","))
    DCM.field = strsplit(getenv('FIELD'), ',')
end

%%%%% Set Priors %%%%%%%
DCM.MDP.reward_lr = 0.1;
DCM.MDP.inverse_temp = 2.5;
DCM.MDP.reward_prior = 0;
DCM.MDP.decision_thresh = 2;
DCM.MDP.nondecision_time = .15;

% additional settings
DCM.settings.max_rt = 2;
DCM.settings.min_rt = .3;

if strcmp(DCM.settings.drift_mapping,'action_prob')
    DCM.MDP.drift_baseline = .085;
    DCM.MDP.drift_mod = .5;  
else
    DCM.MDP.drift = 0;
end

if strcmp(DCM.settings.bias_mapping,'action_prob')
    DCM.MDP.bias_mod = .5;  
else
    DCM.MDP.starting_bias = .5;
end


addpath([root 'rsmith/lab-members/clavalley/MATLAB/spm12/']);
addpath([root 'rsmith/lab-members/clavalley/MATLAB/spm12/toolbox/DEM/']); 

[fit_results, DCM] = fit_CPD(root, subject_id, DCM);

fprintf('Final LL: %f \n',fit_results.LL)
fprintf('Final Patch Choice Average Action Prob: %f \n',fit_results.patch_choice_avg_action_prob)
fprintf('Final Dot Motion Average Action Prob: %f \n',fit_results.dot_motion_avg_action_prob)

simfit_results = simfit_CPD(fit_results,DCM);
if (any(ismember(fieldnames(simfit_results), fieldnames(fit_results))))
    error("simfit_results has same fieldname as fit_results");
else 
    fields = fieldnames(simfit_results); % Get the field names of simfit_results
    for i = 1:length(fields)
        fit_results.(fields{i}) = simfit_results.(fields{i}); 
    end
end

writetable(struct2table(fit_results, 'AsArray', true), [result_dir '/RLDDM_fit_' subject_id '.csv']);
save([result_dir '/RLDDM_fit_' subject_id '.mat'], 'DCM');


    % catch ME
    % error_messages{end+1} = sprintf('An unexpected error occurred: %s\n', subject_id, ME.message);
% end
