********************************************************************************
// 2_globals.do
// Purpose: Sets global paths and parameters used in the cleaning do-files
//          (students, parents, etc.)
//
// Instructions:
//   - Adjust the root path for your own system if necessary.
//   - The user just places the two raw data files
//        PoF_PS_Students.sav
//        PoF_PS_Parents.sav
//     in the folder: 1_data/raw
//   - No date or user input is needed; the code runs automatically.
//
// Author: Ugur Diktas, BA Thesis FS25, 12.02.2025
********************************************************************************

// Subfolders

global raw_data        "${root}/1_data/raw"
global processed_data  "${root}/1_data/processed"
global backup          "${root}/1_data/backup"
global data_to_merge   "${root}/1_data/to_merge"
global sensitive_data  "${root}/1_data/sensitive"

// Folder containing logs
global dodir_log       "${root}/3_logfiles"

// Code directories
global dodir_par_stu   "${root}/2_code/PS_Students"
global dodir_par_par   "${root}/2_code/PS_Parents"

********************************************************************************
// Additional parameters
********************************************************************************

* e.g., whether or not to re-download data
global download_ps "no"
