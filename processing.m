% Ensure SPM12 is in your MATLAB path
addpath('./spm12/');

% Function to load a 3D brain file
function [data, header, filename] = load_brain_file(file_path)
    if ~isfile(file_path)
        error('File "%s" does not exist.', file_path);
    end
    [~, name, ext] = fileparts(file_path);
    switch ext
        case {'.nii', '.nii.gz'}
            % Using SPM for NIfTI files
            nii = spm_vol(file_path);
            data = spm_read_vols(nii);
            header = nii;
        otherwise
            error('Unsupported file format.');
    end
    filename = [name, ext];
end

% Function to save data back to a NIfTI file
function save_brain_file(data, header, file_path)
    [~, ~, ext] = fileparts(file_path);
    switch ext
        case {'.nii', '.nii.gz'}
            % Using SPM for NIfTI files
            header.fname = file_path;
            spm_write_vol(header, data);
        otherwise
            error('Unsupported file format.');
    end
end

% Load and prepare data for PLS-R
function [data_matrix, index_matrix, headers, filenames] = prepare_data(file_paths)
    n_files = length(file_paths);
    data_list = cell(n_files, 1);
    index_list = cell(n_files, 1);
    headers = cell(n_files, 1);
    filenames = cell(n_files, 1);

    % Load and roll out each file
    for i = 1:n_files
        [data, header, filename] = load_brain_file(file_paths{i});
        [nx, ny, nz] = size(data);
        rolled_data = data(:);
        index_matrix = reshape(1:(nx * ny * nz), nx, ny, nz);
        data_list{i} = rolled_data;
        index_list{i} = index_matrix(:); % Store indices as vector
        headers{i} = header;
        filenames{i} = filename;
    end

    % Concatenate data
    data_matrix = cat(2, data_list{:});
    index_matrix = cat(2, index_list{:});
end

% Example usage
file_paths = {'./MoAEpilot/sub-01/anat/sub-01_T1w.nii'}; % Update with actual paths
[data_matrix, index_matrix, headers, filenames] = prepare_data(file_paths);

% Placeholder for PLS-R results for testing purposes
pls_results = data_matrix; % Assuming PLS-R results have the same shape for testing

% Reconstruct the data back into 3D space
for i = 1:length(file_paths)
    [nx, ny, nz] = deal(headers{i}.dim(1), headers{i}.dim(2), headers{i}.dim(3));
    reconstructed_data = reshape(pls_results(:, i), [nx, ny, nz]);

    % Ensure the output directory exists
    output_dir = './results/'; % Update with the desired output directory
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    save_path = fullfile(output_dir, ['result_' filenames{i}]);
    save_brain_file(reconstructed_data, headers{i}, save_path);
    fprintf('Saved processed data to %s\n', save_path);
end
