function [fit_results, DCM] = fit_CPD(root, subject_id, DCM)

    data_dir = [root '/NPC/Analysis/T1000/data-organized/' subject_id '/T0/behavioral_session/'] % always in T0?

    has_practice_effects = false;
    % Manipulate Data
    directory = dir(data_dir);
    % sort by date
    dates = datetime({directory.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    % Sort the dates and get the sorted indices
    [~, sortedIndices] = sort(dates);
    % Use the sorted indices to sort the structure array
    sortedDirectory = directory(sortedIndices);
    index_array = find(arrayfun(@(n) contains(sortedDirectory(n).name, 'CPD-R1-_BEH'),1:numel(sortedDirectory)));
    if length(index_array) > 1
        disp("WARNING, MULTIPLE BEHAVIORAL FILES FOUND FOR THIS ID. USING THE FIRST FULL ONE")
    end

    for k = 1:length(index_array)
        file_index = index_array(k);
        file = [data_dir sortedDirectory(file_index).name];

        subdat = readtable(file);
        % Practice is usually 60 trials but can be more/less. Games will always be 290 trials            
        % event code 13 signals final score shown. complete file!!!
        if any(subdat.event_code == 13)
            break;
        else
            % if the participant doesn't have any more files to look
            % through, throw an error because did not finish
            if k == length(index_array)
                error("Participant does not have a complete behavioral file");
            else
                % if they made it passed trial 60, indicate that they have
                % practice effects
                if max(subdat.trial_number) >= 60
                    has_practice_effects = true;
                end
                continue;
            end
        end
    end
    last_practice_trial = max(subdat.trial_number) - 290;
    first_game_trial = min(find(subdat.trial_number == last_practice_trial+1));
    clean_subdat = subdat(first_game_trial:end, :);
    
    
    clean_subdat_filtered = clean_subdat(clean_subdat.event_code==7 | clean_subdat.event_code==8 | clean_subdat.event_code==9,:);
    DCM.behavioral_file = clean_subdat_filtered;
    % take the last 290 trials
    % event code 7 is game onset, event code 8 means they open a patch, event code 9 means they
    % accept dot motion.
    % note that the result column indicates the correct patch for the first
    % row. For the last row, it indicates if participant chose the correct
    % patch (1) or incorrect patch (0)
    games = cell(1,290);
    for (trial_number=1:290)
        game = clean_subdat_filtered(clean_subdat_filtered.trial_number == trial_number+last_practice_trial,:);
        game.accept_reject_rt = nan(height(game),1);
        for (row=2:height(game)-1)
            game.accept_reject_rt(row) = str2double(game.response_time(row+1)) - str2double(game.response_time(row));
        end
        game = game(1:end-1,:);
        % note that participants must accept a dot motion for trial to
        % continue
        game.accepted_dot_motion = zeros(height(game), 1); % Set all values to 0
        game.accepted_dot_motion(end) = 1; % set last value to 1
        
        games(trial_number) = {game};
    end
    
    DCM.U = games;
    DCM.Y = 0;
    DCM.settings.sim = 0;

    
    CPD_fit_output= inversion_CPD(DCM);
    
    field = DCM.field;
    for i = 1:length(field)
        if any(strcmp(field{i},{'reward_lr','starting_bias', 'drift_mod', 'bias_mod'}))
            params.(field{i}) = 1/(1+exp(-CPD_fit_output.Ep.(field{i}))); 
        elseif any(strcmp(field{i},{'inverse_temp','decision_thresh'}))
            params.(field{i}) = exp( CPD_fit_output.Ep.(field{i}));           
        elseif any(strcmp(field{i},{'reward_prior', 'drift_baseline', 'drift'}))
            params.(field{i}) =  CPD_fit_output.Ep.(field{i});
        elseif any(strcmp(field{i},{'nondecision_time'})) % bound between .1 and .3
            params.(field{i}) =  0.1 + (0.3 - 0.1) ./ (1 + exp(-CPD_fit_output.Ep.(field{i})));     
        else
            error("param not transformed");
        end
    end


    model_output = CPD_RL_DDM_model(params, CPD_fit_output.U, DCM.settings);    
    patch_choice_action_prob = model_output.patch_choice_action_prob;
    dot_motion_action_prob = model_output.dot_motion_action_prob;
    rt_pdf = model_output.dot_motion_rt_pdf;
    patch_choice_model_acc = model_output.patch_choice_model_acc;
    dot_motion_model_acc = model_output.dot_motion_model_acc;
    
    all_values = [patch_choice_action_prob(:); rt_pdf(:)];
    % Remove NaN values
    all_values = all_values(~isnan(all_values));
    % Take the log of the remaining values and sum them
    fit_results.id = subject_id;
    fit_results.has_practice_effects = has_practice_effects;
    fit_results.num_practice_trials = last_practice_trial + 1;
    fit_results.num_irregular_rts = model_output.num_irregular_rts;
    

    fit_results.LL = sum(log(all_values));
    fit_results.patch_choice_avg_action_prob = mean(patch_choice_action_prob(~isnan(patch_choice_action_prob)));
    fit_results.patch_choice_avg_model_acc = mean(patch_choice_model_acc(~isnan(patch_choice_model_acc)));
    fit_results.dot_motion_avg_action_prob = mean(dot_motion_action_prob(~isnan(dot_motion_action_prob)));
    fit_results.dot_motion_avg_model_acc = mean(dot_motion_model_acc(~isnan(dot_motion_model_acc)));
    fit_results.F = CPD_fit_output.F;

    setting_names = fieldnames(DCM.settings);
    for i=1:length(setting_names)
        fit_results.(['settings_' setting_names{i}]) = DCM.settings.(setting_names{i});
    end
    
    field = fieldnames(DCM.MDP);
    for i=1:length(field)
        fit_results.(['prior_' field{i}]) = DCM.MDP.(field{i});
    end
    for i=1:length(field)
        fit_results.(['fit_' field{i}]) = params.(field{i});
    end




end