% get probabilities of true action for each trial 

function action_probs = CPD_RL_DDM_model(params, trials, settings)
patch_choice_action_prob = nan(2,290);
patch_choice_model_acc = nan(2,290);

dot_motion_action_prob = nan(2,290);
dot_motion_model_acc = nan(2,290);

dot_motion_rt_pdf = nan(2,290);

rng(23);
learning_rate = params.reward_lr;
inverse_temp = params.inverse_temp;
reward_prior = params.reward_prior;
decision_thresh = params.decision_thresh;

% get max reaction time
max_rt = -inf;  % Initialize with a very small number
for i = 1:length(trials)
    table_i = trials{i};  % Extract the table from the i-th cell
    max_rt_i = max(str2double(table_i.accept_reject_rt));  % Find the max for the current table
    if max_rt_i > max_rt  % Update the global max if necessary
        max_rt = max_rt_i;
    end
    if settings.sim
        % delete all but row 1
        trials{i} = trials{i}(1, :);
    end
end
% initialize reward distribution
choice_rewards = [reward_prior, reward_prior, reward_prior];

% loop over each trial 
for trial = 1:length(trials)
    current_trial = trials{trial};
    if settings.sim
        trial_length = 2; % set max trial length and break if necessary
    else
        trial_length = min(sum(current_trial.event_code == 8), 2); % at most fit first two choices
    end
    correct_choice = current_trial(1,'result').result;
    for t = 1:trial_length
        
        reward_probabilities = softmax_rows(choice_rewards);
        reward_probabilities_temp = softmax_rows(choice_rewards*inverse_temp);
        
        if settings.sim
            u = rand(1,1);
            true_action = find(cumsum(reward_probabilities_temp) >= u, 1);
            true_action = true_action - 1; % match the coding of choices from task
        else
            current_row = current_trial(t+1, :); % first row corresponds to event code 7
            true_action = str2double(current_row.response);
            true_rt = str2double(current_row.accept_reject_rt);
        end
        
        if t == 1
            outcome = zeros(1,3);
            patch_choice_action_prob(t,trial) = reward_probabilities_temp(true_action+1);
            patch_choice_model_acc(t,trial) = patch_choice_action_prob(t,trial) == max(reward_probabilities_temp);
            % choice prob without inverse temp
            patch_choice_prob =  reward_probabilities(true_action+1);
            
            if contains(settings.drift_mapping, 'action_prob')
                drift = params.drift_baseline + params.drift_mod*(patch_choice_prob - .5);
            else
                drift = params.drift;
            end
            if contains(settings.bias_mapping, 'action_prob')
                starting_bias = .5 + params.bias_mod*(patch_choice_prob - .5);
            else
                starting_bias = params.starting_bias;
            end
            
            if settings.sim
                % accepting dot motion
                min_time = 0;
                max_time = min_time+.001;
                prob_accept_dots = [];
                while max_time < max_rt
                    prob_accept_dots = [prob_accept_dots integral(@(y) wfpt(y,-drift,decision_thresh,1-starting_bias),min_time,max_time)];
                    min_time = min_time+.001;
                    max_time = min_time+.001;
                end
                % rejecting dot motion
                min_time = 0;
                max_time = min_time+.001;
                prob_reject_dots = [];
                while max_time < max_rt
                    prob_reject_dots = [prob_reject_dots integral(@(y) wfpt(y,drift,decision_thresh,starting_bias),min_time,max_time)];
                    min_time = min_time+.001;
                    max_time = min_time+.001;
                end
                % Combine probabilities of accept and reject
                combined_probs = [prob_accept_dots, prob_reject_dots];
                actions = 1:length(combined_probs);
                % Sample action based on combined probabilities
                sampled_action = randsample(actions, 1, true, combined_probs);
                actions_for_accept = length(actions)/2;
                if sampled_action < actions_for_accept
                    % accepted dot motion
                    true_rt = sampled_action*.001;
                else
                    % rejected dot motion
                    true_rt = (sampled_action - actions_for_accept)*.001;
                end
                
            else
               % negative drift and lower bias entail greater probability of
               % accepting dot motion
                if t == height(current_trial)-1 % chose to accept dot motion
                    drift = drift * -1;
                    starting_bias = 1 - starting_bias;
                end
                
                dot_motion_rt_pdf(t,trial) = wfpt(true_rt, drift, decision_thresh, starting_bias);
                dot_motion_action_prob(t,trial) = integral(@(y) wfpt(y,drift,decision_thresh,starting_bias),0,max_rt); % participants have .8 seconds to accept/reject dot motion       
            end
            
            
            if trial_length > 1 % opened another patch after this one
               prediction_error = learning_rate*(-1 - (choice_rewards(:, true_action+1)));
               choice_rewards(:, true_action+1) = choice_rewards(:, true_action+1) + prediction_error;
            else % accepted the first patch
                outcome = outcome -1;
                outcome(true_action + 1) = 1;
                prediction_error = learning_rate*(outcome - choice_rewards);
                choice_rewards = choice_rewards + prediction_error;
            end

        else % second choice (the first choice was wrong) -NL
            previous_row = current_trial(t, :); % notice it's not t+1
            previous_result_idx = str2double(previous_row.response)+1;
            % zero probability of choosing previous patch again
            reward_probabilities_temp(:,previous_result_idx) = exp(-16);
            % renormalize two remaining choices
            row_sums = sum(reward_probabilities_temp, 2);
            reward_probabilities_temp = bsxfun(@rdivide, reward_probabilities_temp, row_sums);
            patch_choice_action_prob(t,trial) = reward_probabilities_temp(true_action+1);
            patch_choice_model_acc(t,trial) = patch_choice_action_prob(t,trial) == max(reward_probabilities_temp);
            
            % do the same thing but for reward probs without temp param
            reward_probabilities(:,previous_result_idx) = exp(-16);
            % renormalize two remaining choices
            row_sums = sum(reward_probabilities, 2);
            reward_probabilities = bsxfun(@rdivide, reward_probabilities, row_sums);
            patch_choice_prob =  reward_probabilities(true_action+1);

            
            if contains(settings.drift_mapping, 'action_prob')
                drift = params.drift_baseline + params.drift_mod*(patch_choice_prob - .5);
            else
                drift = params.drift;
            end
            if contains(settings.bias_mapping, 'action_prob')
                starting_bias = .5 + params.bias_mod*(patch_choice_prob - .5);
            else
                starting_bias = params.starting_bias;
            end
            
           % negative drift and lower bias entail greater probability of
           % accepting dot motion
            if t == height(current_trial)-1 % chose to accept dot motion
                drift = drift * -1;
                starting_bias = 1 - starting_bias;
            end
            
            dot_motion_rt_pdf(t,trial) = wfpt(true_rt, drift, decision_thresh, bias);
            dot_motion_action_prob(t,trial) = integral(@(y) wfpt(y,drift,decision_thresh,bias),0,max_rt); % participants have .8 seconds to accept/reject dot motion

            outcome = zeros(1, 3);
            outcome = outcome - 1; 
            outcome(correct_choice + 1) = 1; 
            columnIndices = true(1, 3);
            columnIndices(previous_result_idx) = false; % already updated first choice so don't need to do it again
            prediction_error = learning_rate * (outcome(:, columnIndices) - choice_rewards(:, columnIndices)); % only the columns where 'columnIndices' is 'true' are considered in the calcu of the PE
            choice_rewards(:, columnIndices) = choice_rewards(:, columnIndices) + prediction_error;
        
        end
    end
end
action_probs.patch_choice_action_prob = patch_choice_action_prob;
action_probs.patch_choice_model_acc = patch_choice_model_acc;
action_probs.dot_motion_action_prob = dot_motion_action_prob;
action_probs.dot_motion_model_acc = dot_motion_model_acc;
action_probs.dot_motion_rt_pdf = dot_motion_rt_pdf;

end



%% functions 
function matrix = softmax_rows(matrix)
    % Subtract the maximum value from each row for numerical stability
    matrix = bsxfun(@minus, matrix, max(matrix, [], 2));
    
    % Calculate the exponent of each element
    exponents = exp(matrix);
    
    % Calculate the sum of exponents for each row
    row_sums = sum(exponents, 2);
    
    % Divide each element by the sum of its row
    matrix = bsxfun(@rdivide, exponents, row_sums);
end
