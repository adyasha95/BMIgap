%% Load Data
dataFilePath = '/.../Data.mat';
load(dataFilePath);

HC_sel = readtable('table_with_IXI_PRONIA_NORM_MUc_unif_AGE_ABMI_withBMIgapcorrected_16022022.xlsx');
HC_remaining = readtable('table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROP = readtable('table_with_PRONIAROP_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROD = readtable('table_with_PRONIAROD_withBMIgapcorrected_16022022.xlsx');
PRONIA_CHR = readtable('table_with_PRONIACHR_withBMIgapcorrected_16022022.xlsx');

%% Define Groups
pronia_norm = HC_sel(contains(HC_sel.Site_name, ...
    {'MilanNig','UBARI','UBS','UKK','UMUENS','Uni BHAM','Uni Turku','Uni Udine','LMU'}), :);
pronia_remaining = HC_remaining(contains(HC_remaining.Site_name, ...
    {'MilanNig','UBARI','UBS','UKK','UMUENS','Uni BHAM','Uni Turku','Uni Udine','LMU'}), :);
MUC_SCZ = readtable('table_with_MUC_SCZ_withBMIgapcorrected_16022022.xlsx');

%% Helper Function to Compute Subscale Totals
computeSubscaleTotal = @(table, columns) nansum(table{:, columns}, 2);

%% Compute PANSS Scores
PANSS_general_columns = compose('PANSS_G%02d_T0', 1:16);
Tables.PANSS_Gen = computeSubscaleTotal(Tables, PANSS_general_columns);

PANSS_pos_columns = compose('PANSS_P%01d_T0', 1:7);
Tables.PANSS_Pos = computeSubscaleTotal(Tables, PANSS_pos_columns);

PANSS_neg_columns = compose('PANSS_N%01d_T0', 1:7);
Tables.PANSS_Neg = computeSubscaleTotal(Tables, PANSS_neg_columns);

Tables.PANSS_Tot = nansum(Tables{:, {'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen'}}, 2);

%% Compute SANS Scores
SANS_columns = compose('SANS_%02d_T0', 1:25);
Tables.SANS_SUM = computeSubscaleTotal(Tables, SANS_columns);

%% Compute WHOQOL Scores
WHOQOL_columns = compose('WHOQOL_%02d_T0', 1:26);
Tables.WHOQOL_sum = computeSubscaleTotal(Tables, WHOQOL_columns);

%% Join Clinical Data
clin_table = Tables(:, {'PSN', 'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen', 'PANSS_Tot', ...
                        'GAF_S_PastMonth_Screening', 'GAF_DI_PastMonth_Screening', ...
                        'GF_R_1_Current_T0', 'GF_S_1_Current_T0', ...
                        'SANS_SUM', 'BDI_sum_T0', 'WHOQOL_sum'});

PRONIA_CHR = join(PRONIA_CHR, clin_table, 'Keys', 'PSN');
PRONIA_ROP = join(PRONIA_ROP, clin_table, 'Keys', 'PSN');
PRONIA_ROD = join(PRONIA_ROD, clin_table, 'Keys', 'PSN');
pronia_norm = join(pronia_norm, clin_table, 'Keys', 'PSN');
pronia_remaining = join(pronia_remaining, clin_table, 'Keys', 'PSN');

%% Compute Group Statistics
clinical_items = {'PANSS_Tot', 'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen', ...
                  'SANS_SUM', 'BDI_sum_T0', 'GAF_S_PastMonth_Screening', ...
                  'GAF_DI_PastMonth_Screening', 'GF_S_1_Current_T0', ...
                  'GF_R_1_Current_T0', 'WHOQOL_sum'};

calculate_group_stats = @(table) struct( ...
    'mean', mean(table{:, clinical_items}, 'omitnan'), ...
    'std', std(table{:, clinical_items}, 'omitnan'));

CHR_stats = calculate_group_stats(PRONIA_CHR);
ROD_stats = calculate_group_stats(PRONIA_ROD);
norm_stats = calculate_group_stats(pronia_norm);
remaining_stats = calculate_group_stats(pronia_remaining);

disp('CHR Group Statistics:');
disp(CHR_stats);
disp('ROD Group Statistics:');
disp(ROD_stats);
disp('Norm Group Statistics:');
disp(norm_stats);
disp('Remaining Group Statistics:');
disp(remaining_stats);

%% Perform ANOVA Tests
performAnova = @(dataGroups) anova1(dataGroups{1}, vertcat(dataGroups{2:end}));

anovaGroups = { ...
    {pronia_norm.BDI_sum_T0, PRONIA_ROD.BDI_sum_T0, PRONIA_CHR.BDI_sum_T0}, ...
    {pronia_norm.GAF_S_PastMonth_Screening, PRONIA_ROD.GAF_S_PastMonth_Screening, PRONIA_CHR.GAF_S_PastMonth_Screening}, ...
    {pronia_norm.GAF_DI_PastMonth_Screening, PRONIA_ROD.GAF_DI_PastMonth_Screening, PRONIA_CHR.GAF_DI_PastMonth_Screening}, ...
    {pronia_norm.GF_S_1_Current_T0, PRONIA_ROD.GF_S_1_Current_T0, PRONIA_CHR.GF_S_1_Current_T0}, ...
    {pronia_norm.GF_R_1_Current_T0, PRONIA_ROD.GF_R_1_Current_T0, PRONIA_CHR.GF_R_1_Current_T0}, ...
    {pronia_norm.WHOQOL_sum, PRONIA_ROD.WHOQOL_sum, PRONIA_CHR.WHOQOL_sum} ...
};

for i = 1:numel(anovaGroups)
    performAnova(anovaGroups{i});
end

%% Perform t-tests
performTTest = @(group1, group2) ttest2(group1, group2);

ttests = { ...
    {pronia_norm.BDI_sum_T0, pronia_remaining.BDI_sum_T0}, ...
    {pronia_norm.GAF_S_PastMonth_Screening, pronia_remaining.GAF_S_PastMonth_Screening}, ...
    {pronia_norm.GAF_DI_PastMonth_Screening, pronia_remaining.GAF_DI_PastMonth_Screening}, ...
    {pronia_norm.GF_S_1_Current_T0, pronia_remaining.GF_S_1_Current_T0}, ...
    {pronia_norm.GF_R_1_Current_T0, pronia_remaining.GF_R_1_Current_T0}, ...
    {pronia_norm.WHOQOL_sum, pronia_remaining.WHOQOL_sum} ...
};

for i = 1:numel(ttests)
    performTTest(ttests{i}{:});
end