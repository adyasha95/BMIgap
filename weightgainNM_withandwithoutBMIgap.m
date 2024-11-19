%% Clear Workspace and Load Required Data
clear;
load('Data.mat');

HC_sel = readtable('table_with_IXI_PRONIA_NORM_MUc_unif_AGE_ABMI_withBMIgapcorrected_16022022.xlsx');
HC_remaining = readtable('table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROP = readtable('table_with_PRONIAROP_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROD = readtable('table_with_PRONIAROD_withBMIgapcorrected_16022022.xlsx');
PRONIA_CHR = readtable('table_with_PRONIACHR_withBMIgapcorrected_16022022.xlsx');
MUC_SCZ = readtable('table_with_MUC_SCZ_withBMIgapcorrected_16022022.xlsx');

%% Filter Data by Site
pronia_norm = HC_sel(contains(HC_sel.Site_name, {'MilanNig', 'UBARI', 'UBS', 'UKK', 'UMUENS', 'Uni BHAM', 'Uni Turku', 'Uni Udine', 'LMU'}), :);
pronia_remaining = HC_remaining(contains(HC_remaining.Site_name, {'MilanNig', 'UBARI', 'UBS', 'UKK', 'UMUENS', 'Uni BHAM', 'Uni Turku', 'Uni Udine', 'LMU'}), :);

%% PANSS General Score Calculation
PANSS_general_columns = {'PANSS_G01_T0', 'PANSS_G02_T0', 'PANSS_G03_T0', ...
    'PANSS_G04_T0', 'PANSS_G05_T0', 'PANSS_G06_T0', ...
    'PANSS_G07_T0', 'PANSS_G08_T0', 'PANSS_G09_T0', ...
    'PANSS_G10_T0', 'PANSS_G11_T0', 'PANSS_G12_T0', ...
    'PANSS_G13_T0', 'PANSS_G14_T0', 'PANSS_G15_T0', ...
    'PANSS_G16_T0'};
Tables.PANSS_Gen = nansum(Tables{:, PANSS_general_columns}, 2);

%% PANSS Positive and Negative Scores
PANSS_pos_columns = {'PANSS_P1_T0', 'PANSS_P2_T0', 'PANSS_P3_T0', ...
    'PANSS_P4_T0', 'PANSS_P5_T0', 'PANSS_P6_T0', 'PANSS_P7_T0'};
Tables.PANSS_Pos = nansum(Tables{:, PANSS_pos_columns}, 2);

PANSS_neg_columns = {'PANSS_N1_T0', 'PANSS_N2_T0', 'PANSS_N3_T0', ...
    'PANSS_N4_T0', 'PANSS_N5_T0', 'PANSS_N6_T0', 'PANSS_N7_T0'};
Tables.PANSS_Neg = nansum(Tables{:, PANSS_neg_columns}, 2);

%% Total PANSS Score
Tables.PANSS_Tot = nansum(Tables{:, {'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen'}}, 2);

%% SANS and WHOQOL Scores
SANS_columns = strcat('SANS_', compose('%02d', 1:25), '_T0');
Tables.SANS_SUM = nansum(Tables{:, SANS_columns}, 2);

WHOQOL_columns = strcat('WHOQOL_', compose('%02d', 1:26), '_T0');
Tables.WHOQOL_sum = nansum(Tables{:, WHOQOL_columns}, 2);

%% Clinical Table Extraction
clin_table = Tables(:, {'PSN', 'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen', 'PANSS_Tot', ...
    'GAF_S_PastMonth_Screening', 'GAF_DI_PastMonth_Screening', ...
    'GF_R_1_Current_T0', 'GF_S_1_Current_T0', 'SANS_SUM', ...
    'BDI_sum_T0', 'WHOQOL_sum'});

%% Join Clinical Data with PRONIA Groups
PRONIA_CHR = join(PRONIA_CHR, clin_table, 'keys', 'PSN');
PRONIA_ROP = join(PRONIA_ROP, clin_table, 'keys', 'PSN');
PRONIA_ROD = join(PRONIA_ROD, clin_table, 'keys', 'PSN');
pronia_norm = join(pronia_norm, clin_table, 'keys', 'PSN');
pronia_remaining = join(pronia_remaining, clin_table, 'keys', 'PSN');

%% Group Statistics Calculation
clinical_items = {'PANSS_Tot', 'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen', ...
    'SANS_SUM', 'BDI_sum_T0', 'GAF_S_PastMonth_Screening', ...
    'GAF_DI_PastMonth_Screening', 'GF_S_1_Current_T0', ...
    'GF_R_1_Current_T0', 'WHOQOL_sum'};

calculate_group_stats = @(group_table) struct(...
    'mean', mean(group_table{:, clinical_items}, 'omitnan'), ...
    'stdev', std(group_table{:, clinical_items}, 'omitnan'));

CHR_stats = calculate_group_stats(PRONIA_CHR);
ROD_stats = calculate_group_stats(PRONIA_ROD);
norm_stats = calculate_group_stats(pronia_norm);
remaining_stats = calculate_group_stats(pronia_remaining);

%% Display Statistics
disp('CHR Group Statistics:');
disp(CHR_stats);
disp('ROD Group Statistics:');
disp(ROD_stats);
disp('Norm Group Statistics:');
disp(norm_stats);
disp('Remaining Group Statistics:');
disp(remaining_stats);

%% ANOVA Analysis for Clinical Metrics
anova_metrics = {'BDI_sum_T0', 'GAF_S_PastMonth_Screening', ...
    'GAF_DI_PastMonth_Screening', 'GF_S_1_Current_T0', ...
    'GF_R_1_Current_T0', 'WHOQOL_sum', 'PANSS_Tot', ...
    'PANSS_Pos', 'PANSS_Neg', 'PANSS_Gen', 'SANS_SUM'};

for i = 1:length(anova_metrics)
    metric = anova_metrics{i};
    [h, p, stats] = anova1([pronia_norm.(metric); PRONIA_ROD.(metric); PRONIA_CHR.(metric)], ...
        [ones(size(pronia_norm, 1), 1); 2 * ones(size(PRONIA_ROD, 1), 1); 3 * ones(size(PRONIA_CHR, 1), 1)], ...
        'off');
    fprintf('%s: p-value = %.3f\n', metric, p);
end

%% T-Test Comparisons
metrics_for_ttest = {'BDI_sum_T0', 'GAF_S_PastMonth_Screening', ...
    'GAF_DI_PastMonth_Screening', 'GF_S_1_Current_T0', ...
    'GF_R_1_Current_T0', 'WHOQOL_sum'};

for i = 1:length(metrics_for_ttest)
    metric = metrics_for_ttest{i};
    [h, p, ci, stats] = ttest2(pronia_norm.(metric), pronia_remaining.(metric));
    fprintf('%s: t-test p-value = %.3f\n', metric, p);
end