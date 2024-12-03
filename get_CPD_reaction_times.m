function get_CPD_reaction_times()
    dbstop if error;
    % use RTs from subjects that were fit
    fit_table = readtable('L:\rsmith\lab-members\cgoldman\change_point_detection\CPD_analysis\model_results_compiled\CPD_fit_12-2-2024_model1.csv');
    subjects = fit_table.id;
    everyones_rts = {};

    for i = 1:height(subjects)
        subject_id = char(subjects{i,1});
        data_dir = ['L:\NPC\Analysis\T1000\data-organized\' subject_id '\T0\behavioral_session\']; % always in T0?

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
            % event code 15 signals early quit
            if any(subdat.event_code == 15)
                % if they made it passed trial 60, indicate that they have
                % practice effects and move on
                if max(subdat.trial_number) >= 60
                    has_practice_effects = true;
                end
                continue;
            else
                % found a complete file!
                break;
            end
        end
        
        
        
        last_practice_trial = max(subdat.trial_number) - 290;
        first_game_trial = min(find(subdat.trial_number == last_practice_trial+1));
        clean_subdat = subdat(first_game_trial:end, :);

        clean_subdat_filtered = clean_subdat(clean_subdat.event_code==7 | clean_subdat.event_code==8 | clean_subdat.event_code==9,:);
        % take the last 290 trials
        % event code 7 is game onset, event code 8 means they open a patch, event code 9 means they
        % accept dot motion.
        % note that the result column indicates the correct patch for the first
        % row. For the last row, it indicates if participant chose the correct
        % patch (1) or incorrect patch (0)
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
%             game.accepted_dot_motion(end) = 1; % set last value to 1
            
            % added this line to extract rts
            everyones_rts = [everyones_rts; game.accept_reject_rt];
        end
    end
    % Concatenate all the data from the cell array into one numeric array
    everyones_rts_long = vertcat(everyones_rts{:});

    % Remove NaN values
    everyones_rts_long = everyones_rts_long(~isnan(everyones_rts_long));
%     writematrix(everyones_rts_long, 'all_CPD_RTs.csv');


end