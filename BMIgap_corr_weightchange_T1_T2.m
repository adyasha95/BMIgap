% Add paths to required directories

% Define input file paths
HC_sel_path = '/table_with_IXI_PRONIA_NORM_MUc_unif_AGE_ABMI_withBMIgapcorrected_16022022.xlsx';
HC_remaining_path = '/table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_withBMIgapcorrected_16022022.xlsx';
PRONIA_ROP_path = '/table_with_PRONIAROP_withBMIgapcorrected_16022022.xlsx';
PRONIA_ROD_path = '/table_with_PRONIAROD_withBMIgapcorrected_16022022.xlsx';
PRONIA_CHR_path = '/table_with_PRONIACHR_withBMIgapcorrected_16022022.xlsx';
MUC_SCZ_path = '/table_with_MUC_SCZ_withBMIgapcorrected_16022022.xlsx';

query_path = '/AK_mediction_query/PQT_v53_14_Jun_2024_AKmed/PQT_v53_14_Jun_2024_AKmed/DATA/PQT_v53_14_Jun_2024_AKmed_Data.mat';

% Load data tables
HC_sel = readtable(HC_sel_path);
HC_remaining = readtable(HC_remaining_path);
PRONIA_ROP = readtable(PRONIA_ROP_path);
PRONIA_ROD = readtable(PRONIA_ROD_path);
PRONIA_CHR = readtable(PRONIA_CHR_path);

% Load query data
load(query_path);

% Update variable names in HC data
HC_sel.Properties.VariableNames{9} = 'BMIgap_HC_corrected';
HC_remaining.Properties.VariableNames{8} = 'BMIgap_HC';
HC_remaining.Properties.VariableNames{9} = 'BMIgap_HC_corrected';
HC_remaining.Properties.VariableNames{10} = 'predicted_BMI_HC';

% Combine HC datasets
HC_all = [HC_sel; HC_remaining];

% Extract PRONIA site data for HC
PRONIA_sites = {'LMU', 'MilanNig', 'UBARI', 'UBS', 'UKK', 'UMUENS', 'Uni Udine', 'Uni BHAM', 'Uni Turku'};
PRONIA_HC = HC_all(ismember(HC_all.Site_name, PRONIA_sites), :);

% Join PRONIA weight and height data at Screening (T0)
PRONIA_HC_weight_T0 = extract_measurement('SOMAT_02_Weight_corr_Screening', PRONIA_HC);
PRONIA_HC_height_T0 = extract_measurement('SOMAT_01_Hight_corr_Screening', PRONIA_HC, 100);
PRONIA_HC_height_weight_T0 = join_measurements(PRONIA_HC_weight_T0, PRONIA_HC_height_T0);

% Calculate BMI at T0
PRONIA_HC_height_weight_T0.BMI_T0 = calculate_BMI(...
    PRONIA_HC_height_weight_T0.SOMAT_02_Weight_corr_Screening, ...
    PRONIA_HC_height_weight_T0.SOMAT_01_Hight_corr_Screening);

% Process T1 and T2 measurements
[PRONIA_HC_T1, PRONIA_HC_T2] = process_T1_T2(PRONIA_HC_height_weight_T0, 'HC');

% Combine T0, T1, T2 data
PRONIA_HC_T0_T1_T2 = join_T0_T1_T2(PRONIA_HC_height_weight_T0, PRONIA_HC_T1, PRONIA_HC_T2);

% Calculate deltas
PRONIA_HC_T0_T1_T2 = calculate_deltas(PRONIA_HC_T0_T1_T2, 'BMI_T0', 'BMI_T1', 'BMI_T2', ...
    'SOMAT_02_Weight_corr_Screening', 'SOMAT_02_Weight_corr_T1', 'SOMAT_02_Weight_corr_T2');

% Filter and analyze data
analyze_correlations(PRONIA_HC_T0_T1_T2, 'BMIgap_HC_corrected');

% Helper functions
function measurement_table = extract_measurement(measurement_name, source_table, scale_factor)
    if nargin < 3
        scale_factor = 1;
    end
    measurement_table = Tables(ismember(Tables.PSN, source_table.PSN), {measurement_name});
    measurement_table.PSN = measurement_table.Row;
    measurement_table.(measurement_name) = measurement_table.(measurement_name) / scale_factor;
end

function joined_table = join_measurements(table1, table2)
    joined_table = join(table1, table2, 'Keys', 'PSN');
end

function BMI = calculate_BMI(weight, height)
    BMI = weight ./ (height .^ 2);
end

function [T1_table, T2_table] = process_T1_T2(source_table, label)
    T1_height = extract_measurement(['SOMAT_01_Hight_corr_T1'], source_table, 100);
    T1_weight = extract_measurement(['SOMAT_02_Weight_corr_T1'], source_table);
    T1_table = join_measurements(T1_height, T1_weight);

    T2_height = extract_measurement(['SOMAT_01_Hight_corr_T2'], source_table, 100);
    T2_weight = extract_measurement(['SOMAT_02_Weight_corr_T2'], source_table);
    T2_table = join_measurements(T2_height, T2_weight);

    disp([label ' T1 and T2 data processed.']);
end

function combined_table = join_T0_T1_T2(T0_table, T1_table, T2_table)
    combined_table = join(T0_table, T1_table, 'Keys', 'PSN');
    combined_table = join(combined_table, T2_table, 'Keys', 'PSN');
end

function updated_table = calculate_deltas(source_table, T0_col, T1_col, T2_col, weight_col_T0, weight_col_T1, weight_col_T2)
    updated_table = source_table;
    updated_table.BMIdelta_T1 = updated_table.(T1_col) - updated_table.(T0_col);
    updated_table.BMIdelta_T2 = updated_table.(T2_col) - updated_table.(T0_col);
    updated_table.weightdelta_T1 = updated_table.(weight_col_T1) - updated_table.(weight_col_T0);
    updated_table.weightdelta_T2 = updated_table.(weight_col_T2) - updated_table.(weight_col_T0);
end

function analyze_correlations(data_table, bmi_gap_col)
    % Example: Filter for non-NaN values
    T1_data = data_table(~isnan(data_table.BMIdelta_T1), :);
    T2_data = data_table(~isnan(data_table.BMIdelta_T2), :);

    % Perform correlations
    disp('T1 Correlations:');
    [r, p] = corr(T1_data.(bmi_gap_col), T1_data.BMIdelta_T1);
    disp(['R: ', num2str(r), ', P: ', num2str(p)]);

    disp('T2 Correlations:');
    [r, p] = corr(T2_data.(bmi_gap_col), T2_data.BMIdelta_T2);
    disp(['R: ', num2str(r), ', P: ', num2str(p)]);
end