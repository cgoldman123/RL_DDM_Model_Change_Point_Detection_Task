function simfit_results = simfit_CPD(fit_results, DCM)

% simulate behavior using the data in DCM.games, which tells us which patch
% contained the winning dot motion for each trial
params = struct();
fields = fieldnames(fit_results);
for i = 1:length(fields)
    if startsWith(fields{i}, 'fit_')
        params.(erase(fields{i}, 'fit_')) = fit_results.(fields{i});
    end
end
DCM.settings.sim = 1;
simmed_output = CPD_RL_DDM_model(params, DCM.U, DCM.settings);
DCM.U = simmed_output.simmed_trials;
DCM.settings.sim=0;
CPD_simfit_output= inversion_CPD(DCM);


field = DCM.field;
for i = 1:length(field)
    if any(strcmp(field{i},{'reward_lr','starting_bias', 'drift_mod', 'bias_mod'}))
        params.(field{i}) = 1/(1+exp(-CPD_simfit_output.Ep.(field{i}))); 
    elseif any(strcmp(field{i},{'inverse_temp','decision_thresh'}))
        params.(field{i}) = exp( CPD_simfit_output.Ep.(field{i}));           
    elseif any(strcmp(field{i},{'reward_prior', 'drift_baseline', 'drift'}))
        params.(field{i}) =  CPD_simfit_output.Ep.(field{i});
    elseif any(strcmp(field{i},{'nondecision_time'})) % bound between .1 and .3
        params.(field{i}) =  0.1 + (0.3 - 0.1) ./ (1 + exp(-CPD_simfit_output.Ep.(field{i})));     
    else
        error("param not transformed");
    end
end

simfit_results.simfit_F = CPD_simfit_output.F;
field = fieldnames(DCM.MDP);
for i=1:length(field)
    simfit_results.(['simfit_' field{i}]) = params.(field{i});
end

end