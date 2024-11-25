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

sim_data = CPD_RL_DDM_model(params, DCM.U, 1);








end