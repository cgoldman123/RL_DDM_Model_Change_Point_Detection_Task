function get_CPD_subjects()

dbstop if error;

% Define the root directory based on OS
if ispc
    root = 'L:/';
else
    root = '/media/labs/';
end
result_file = [root 'rsmith/lab-members/cgoldman/change_point_detection/CPD_subjects.csv'];
data_dir = [root 'NPC/Analysis/T1000/data-organized/'];
subfolders = dir(data_dir);

% Initialize a cell array to store subject IDs
subject_ids = {};

% Loop through subfolders to check for CSV files
for i = 1:length(subfolders)
    subject_id = subfolders(i).name;
    
    % Skip '.' and '..' folders
    if startsWith(subject_id, '.')
        continue;
    end
    
    % Construct the file path for the CSV file
    csv_file = fullfile(data_dir, subject_id, 'T0', 'behavioral_session', [subject_id '-T0-_CPD-R1-_BEH.csv']);
    
    % Check if the CSV file exists
    if exist(csv_file, 'file') == 2
        % Append the subject ID to the list
        subject_ids{end+1} = subject_id; 
    end
end
subject_ids = unique(subject_ids);


writetable((cell2table(subject_ids', 'VariableNames', {'id'})), result_file);

    
end