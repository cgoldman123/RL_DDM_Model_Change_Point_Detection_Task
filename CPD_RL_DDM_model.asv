% get probabilities of true action for each trial 

function action_probs = CPD_RL_DDM_model(params, trials, test)
patch_choice_action_prob = nan(2,290);
patch_choice_model_acc = nan(2,290);

dot_motion_action_prob = nan(2,290);
dot_motion_model_acc = nan(2,290);

dot_motion_rt_pdf = nan(2,290);

rng(1);
learning_rate = params.reward_lr;
inverse_temp = params.inverse_temp;
reward_prior = params.reward_prior;
decision_thresh = params.decision_thresh;
starting_bias = params.starting_bias;
drift_baseline = params.drift_baseline;
drift_mod = params.drift_mod;

% loop over each trial 

choice_rewards = [reward_prior, reward_prior, reward_prior];

% retrieve true action/s and results 
for trial = 1:length(trials)
    current_trial = trials{trial};
    trial_length = min(sum(current_trial.event_code == 8), 2); % at most fit first two choices
    correct_choice = current_trial(1,'result').result;
    for t = 1:trial_length
        filtered_rows = current_trial(current_trial.event_code == 8, :);
        current_row = filtered_rows(t, :);
        true_action = str2double(current_row.response);
        true_rt = str2double(current_row.accept_reject_rt);
        reward_probabilities = softmax_rows(choice_rewards*inverse_temp);
        if t == 1
            outcome = zeros(1,3);
            patch_choice_action_prob(t,trial) = reward_probabilities(true_action+1);
            patch_choice_model_acc(t,trial) = patch_choice_action_prob(t,trial) == max(reward_probabilities);
            drift = drift_baseline + drift_mod*(chosen_action_probability - .5);
           % negative drift and lower bias entail greater probability of
           % accepting dot motion
            if t == height(current_trial)-1 % chose to accept dot motion
                drift = drift * -1;
                bias = 1 - starting_bias;
            else
                bias = starting_bias;
            end
            dot_motion_rt_pdf(t,trial) = wfpt(true_rt, drift, decision_thresh, bias);
            
            % simulate actions
%             action_probabilities =reward_probabilities;
%             action_probs{trial}(t,:) = action_probabilities;
%             u = rand(1,1);
%             choice = find(cumsum(action_probabilities) >= u, 1);
% 
%             choice = choice-1;
%             choices{trial}(t, :)= choice;
            

            
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
            previous_row = filtered_rows(t-1, :);
            previous_result_idx = str2double(previous_row.response)+1;
            reward_probabilities(:,previous_result_idx) = exp(-16);
            row_sums = sum(reward_probabilities, 2);
            reward_probabilities = bsxfun(@rdivide, reward_probabilities, row_sums);
            patch_choice_action_prob(t,trial) = reward_probabilities(true_action+1);
            patch_choice_model_acc(t,trial) = patch_choice_action_prob(t,trial) == max(reward_probabilities);
            drift = drift_baseline + drift_mod*(chosen_action_probability - .5);
            if t == height(current_trial)-1 % chose to accept dot motion
                drift = drift * -1;
                bias = 1 - starting_bias;
            else
                bias = 1 - starting_bias;
            end
            dot_motion_rt_pdf(t,trial) = wfpt(true_rt, drift, decision_thresh, bias);

            
            
%             u = rand(1,1);
%             choice = find(cumsum(action_probabilities) >= u, 1);
%             choice = choice - 1; % match the coding of choices from task
%             choices{trial}(t,:) = choice;

            outcome = zeros(1, 3);
            outcome = outcome - 1; 
            outcome(correct_choice + 1) = 1; 
            columnIndices = true(1, 3);
            columnIndices(previous_result_idx) = false;
            prediction_error = learning_rate * (outcome(:, columnIndices) - choice_rewards(:, columnIndices)); % only the columns where 'columnIndices' is 'true' are considered in the calcu of the PE
            choice_rewards(:, columnIndices) = choice_rewards(:, columnIndices) + prediction_error;
        end
    end
end

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
