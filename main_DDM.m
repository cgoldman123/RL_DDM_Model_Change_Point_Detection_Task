function [] = main_DDM(subject_id,result_dir)
    dbstop if error;
    if ispc
        root = 'L:/';
        subject_id = 'AA438'; %AA181 AA438 AB418 AD074
        result_dir = [root 'rsmith\lab-members\cgoldman\change_point_detection\fitting_output\test\'];
    else
        root = '/media/labs/';
    end
    DCM.settings.drift_mapping = 'action_prob';
    DCM.settings.bias_mapping = '';
    DCM.settings.threshold_mapping = '';

    
    %%%%% Set Priors %%%%%%%
    DCM.MDP.reward_lr = 0.1;
    DCM.MDP.inverse_temp = 2;
    DCM.MDP.reward_prior = 0;
    DCM.MDP.decision_thresh = 2;
    DCM.MDP.starting_bias = .5;
    DCM.MDP.drift_baseline = .085;
    DCM.MDP.drift_mod = .5;   
    DCM.MDP.nondecision_time = .15;

    addpath([root 'rsmith/lab-members/clavalley/MATLAB/spm12/']);
    addpath([root 'rsmith/lab-members/clavalley/MATLAB/spm12/toolbox/DEM/']); 
    
    [fit_results, DCM] = fit_CPD(root, subject_id, DCM);
    
    fprintf('Final LL: %f \n',fit_results.LL)
    fprintf('Final Patch Choice Average Action Prob: %f \n',fit_results.patch_choice_avg_action_prob)
    fprintf('Final Dot Motion Average Action Prob: %f \n',fit_results.dot_motion_avg_action_prob)
    
    simfit_results = simfit_CPD(fit_results,DCM);

  writetable(struct2table((fit_results)), [result_dir 'RL_fit_' subject_id '.csv']);
  % save DCM...
end

        % catch ME
        % error_messages{end+1} = sprintf('An unexpected error occurred: %s\n', subject_id, ME.message);
    % end
