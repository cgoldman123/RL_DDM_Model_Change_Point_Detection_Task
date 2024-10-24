function find_num_trials()
% function to figure out how many practice trials are in CPD by looking at
% total number of trials. Testing if it's every greater than 60

dbstop if error;
if ispc
    root = 'L:/';
else
    root = '/media/labs/';
end

data_dir = [root 'NPC/Analysis/T1000/data-organized/'];
subfolders = dir(data_dir);

for i = 1:length(subfolders)
    subfolder = subfolders(i).name;
    
    % Skip the '.' and '..' folders
    if startsWith(subfolder, '.')
        continue;
    end
    
    % Construct the file path
    csv_file = fullfile(data_dir, subfolder, 'T0', 'behavioral_session', [subfolder '-T0-_CPD-R1-_BEH.csv']);
    
    % Check if the CSV file exists
    if exist(csv_file, 'file') == 2
        % Read the CSV file
        data = readtable(csv_file);
        
        % Check if 'trial_number' column exists
        if ismember('trial_number', data.Properties.VariableNames)
            max_trial = max(data.trial_number);
            
            % Check if max trial number is not 349
            if max_trial ~= 349
                fprintf('%s has %d trials\n', subfolder, max_trial);
            end
        else
            fprintf('No trial_number column in %s\n', csv_file);
        end
    else
     %   fprintf('File not found: %s\n', csv_file);
    end
end


    


    
end