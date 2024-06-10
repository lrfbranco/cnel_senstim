% Define the folder to save the converted .m files
output_folder = 'm-files';

% Check if the folder exists, if not, create it
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Find .mlapp files in the current folder
mlapp_files = dir('*.mlapp');

% Loop through each .mlapp file
for k = 1:length(mlapp_files)
    % Get the current .mlapp file name without extension
    [~, name, ~] = fileparts(mlapp_files(k).name);
    
    % Define the temporary output .m file name
    temp_output_file = strcat(name, '_exported.m');
    
    % Define the final output .m file path
    final_output_file = fullfile(output_folder, strcat(name, '.m'));
    
    % Run the conversion to .m file
    diary(temp_output_file);
    type(mlapp_files(k).name);
    diary off;
    
    % Move the temporary output file to the final output path
    movefile(temp_output_file, final_output_file);
end
