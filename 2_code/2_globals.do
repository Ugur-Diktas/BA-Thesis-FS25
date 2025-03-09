********************************************************************************
* 2_globals.do
* ------------------------------------------------------------------------------
* Purpose:
*   - Sets global paths and parameters used in the do-files
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

global root "`c(pwd)'"

// Subfolders
global raw_data        "${root}/1_data/raw"
global processed_data  "${root}/1_data/processed"
global sensitive_data  "${root}/1_data/sensitive"

// Folder containing logs
global dodir_log       "${root}/3_logfiles"

// Code directories
global dodir_par_stu   "${root}/2_code/PS_Students"
global dodir_par_par   "${root}/2_code/PS_Parents"

// Assets
global clean_apprenticeships "${root}/4_assets/clean_apprenticeships"
global parental_occupation_cleaning_new "${root}/4_assets/Parental_occupation_cleaning_new"
global data_to_merge   "${root}/4_assets/to_merge"

// Additional parameters
global download_ps "no"
global debug "yes"
