% get probabilities of true action for each trial 

function model_output = CPD_RL_DDM_model(params, trials, settings)
patch_choice_action_prob = nan(2,290);
patch_choice_model_acc = nan(2,290);

dot_motion_action_prob = nan(2,290);
dot_motion_model_acc = nan(2,290);

dot_motion_rt_pdf = nan(2,290);

rng(23);
learning_rate = params.reward_lr;
inverse_temp = params.inverse_temp;
reward_prior = params.reward_prior;
nondecision_time = params.nondecision_time;

max_rt = 5;  % filter out games with RTs where .5 < RT < .3
min_rt = .3;
% Initialize a logical array to mark valid trials
valid_trials = true(1, length(trials));
for i = 1:length(trials)
    if (~isnan(trials{i}.accept_reject_rt) & ((trials{i}.accept_reject_rt <= min_rt | trials{i}.accept_reject_rt >= max_rt)))
        valid_trials(i) = false; % Mark as invalid
    end
    if settings.sim
        trials{i} = trials{i}(1, :);
    end
end
% Keep only the valid trials for fitting
if ~settings.sim
    trials = trials(valid_trials);
end


% initialize reward distribution
choice_rewards = [reward_prior, reward_prior, reward_prior];

% loop over each trial 
max_trial_length = 2;
for trial = 1:length(trials)
    current_trial = trials{trial};
    correct_choice = current_trial(1,'result').result;
    for t = 1:max_trial_length
        reward_probabilities = softmax_rows(choice_rewards);
        reward_probabilities_temp = softmax_rows(choice_rewards*inverse_temp);
        % can't open patch from the last trial on current trial
        if t==2        
            previous_row = current_trial(t, :); % notice it's not t+1
            previous_result_idx = str2double(previous_row.response)+1;
            reward_probabilities_temp(:,previous_result_idx) = 0; % zero probability of choosing previous patch again
            row_sums = sum(reward_probabilities_temp, 2); % renormalize two remaining choices
            reward_probabilities_temp = bsxfun(@rdivide, reward_probabilities_temp, row_sums);
            reward_probabilities(:,previous_result_idx) = 0; % do the same thing but for reward probs without temp param
            row_sums = sum(reward_probabilities, 2);
            reward_probabilities = bsxfun(@rdivide, reward_probabilities, row_sums);
        end
        
        if settings.sim
            u = rand(1,1);
            patch_action = find(cumsum(reward_probabilities_temp) >= u, 1);
            patch_action = patch_action - 1; % match the coding of choices from task
            % Add the new row to the table
            new_row = {current_trial.trial_number(1), current_trial.trial_type{1}, 8, NaN, 'sim',num2str(patch_action), 0, NaN, 0};
            current_trial = [current_trial; cell2table(new_row, 'VariableNames', current_trial.Properties.VariableNames)];
        else
            current_row = current_trial(t+1, :); % first row corresponds to event code 7
            patch_action = str2double(current_row.response);
            dot_motion_rt = current_row.accept_reject_rt;
        end
        
        outcome = zeros(1,3);
        patch_choice_action_prob(t,trial) = reward_probabilities_temp(patch_action+1);
        patch_choice_model_acc(t,trial) = patch_choice_action_prob(t,trial) == max(reward_probabilities_temp);
        % choice prob without inverse temp
        patch_choice_prob =  reward_probabilities(patch_action+1);

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
        if contains(settings.threshold_mapping, 'action_prob')
            decision_thresh_untransformed = params.thresh_baseline + params.thresh_mod*(patch_choice_prob - .5);
            % softplus function to keep positive
            decision_thresh = log(1+exp(decision_thresh_untransformed));
        else
            decision_thresh = params.decision_thresh;
        end
        
        
        if settings.sim
            % accepting dot motion
            [simmed_rt, accepted_dot_motion] = simulate_DDM(drift, decision_thresh, nondecision_time, starting_bias, 1, .001, realmax);
            % accepted dot motion
            if accepted_dot_motion
                current_trial.result(t+1) = patch_action == correct_choice; % result column is 1 if accepted correct dot motion
                current_trial.accepted_dot_motion(t+1) = 1;
            end
            current_trial.accept_reject_rt(t+1) = simmed_rt;
            trials{trial} = current_trial;
        else
           % negative drift and lower bias entail greater probability of
           % accepting dot motion
            if  current_trial.accepted_dot_motion(t+1) % chose to accept dot motion
                drift = drift * -1;
                starting_bias = 1 - starting_bias;
            end
            dot_motion_rt_pdf(t,trial) = wfpt(dot_motion_rt - nondecision_time, drift, decision_thresh, starting_bias);
            dot_motion_action_prob(t,trial) = integral(@(y) wfpt(y,drift,decision_thresh,starting_bias),0,max_rt - nondecision_time); % participants have .8 seconds to accept/reject dot motion
            dot_motion_model_acc(t,trial) =  dot_motion_action_prob(t,trial) > .5;
        end
        
        
        if t == 1
            % remember it always tells you the right answer when you accept
            if  current_trial.accepted_dot_motion(2) 
                outcome = outcome -1;
                outcome(correct_choice + 1) = 1;
                prediction_error = learning_rate*(outcome - choice_rewards);
                choice_rewards = choice_rewards + prediction_error;
                break; 
            else % opened another patch
                prediction_error = learning_rate*(-1 - (choice_rewards(:, patch_action+1)));
                choice_rewards(:, patch_action+1) = choice_rewards(:, patch_action+1) + prediction_error;
            end
        else % second choice 
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
model_output.patch_choice_action_prob = patch_choice_action_prob;
model_output.patch_choice_model_acc = patch_choice_model_acc;
model_output.dot_motion_action_prob = dot_motion_action_prob;
model_output.dot_motion_model_acc = dot_motion_model_acc;
model_output.dot_motion_rt_pdf = dot_motion_rt_pdf;
model_output.num_valid_trials = length(trials);
if settings.sim
    model_output.simmed_trials = trials;
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
