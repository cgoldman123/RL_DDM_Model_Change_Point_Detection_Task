function get_CPD_reaction_times()
    dbstop if error;
    subjects = readtable('../CPD_subjects.csv');
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
        
        if height(subdat) < 20 || max(subdat.trial_number) < 290
            continue
        else
            last_practice_trial = max(subdat.trial_number) - 290;
            first_game_trial = min(find(subdat.trial_number == last_practice_trial+1));

            % event code 7 is game onset, event code 8 means they open a patch, event code 9 means they

            clean_subdat = subdat(first_game_trial:end, :);

            % Filter rows where event_code is 8 or 9
            filtered_rows = clean_subdat.event_code == 8 | clean_subdat.event_code == 9;

            % Extract the response_time column (cell array) for these rows
            response_times = clean_subdat.response_time(filtered_rows);

            % Further filter out rows where response_time is '0'
            response_times_filtered = response_times(~strcmp(response_times, '0'));

            everyones_rts = [everyones_rts; response_times_filtered];
        end

    end
    everyones_rts = cellfun(@str2double, everyones_rts);


end