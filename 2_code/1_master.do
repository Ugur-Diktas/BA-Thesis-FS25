********************************************************************************
// 1_master.do
// Purpose : Master do-file that runs all cleaning do-files in order
//           for PS_Students and PS_Parents.
//
// Usage   : 
//   1) Place your raw data files in 1_data/raw
//   2) Then just run this 1_master.do to produce anonymised & cleaned data.
//	 !! When debugging, please make sure to cd your Stata terminal to root
//
// Author  : Ugur Diktas, BA Thesis FS25, 12.02.2025
********************************************************************************

clear all
set more off

// 1. Define your root path

if c(username) == "ugurdiktas" {
    // debug pring to show I'm here
    di "I'm here"
    global root "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}

if (c(username) == "jelkeclarysse") {
    global root "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning";
}

// 2. Log settings
cap log close
log using "3_logfiles/1_master.log", replace

// 3. Run the globals file
quietly do "2_code/2_globals.do"

// 4. Clean the Students Data
do "${dodir_par_stu}/1_ps_students_anonymize.do"
do "${dodir_par_stu}/2_ps_students_remove_duplicates.do"
do "${dodir_par_stu}/3_ps_students_clean_beliefs.do"
do "${dodir_par_stu}/4_ps_students_clean_other.do"
do "${dodir_par_stu}/5_ps_students_merge_chars.do"
do "${dodir_par_stu}/6_ps_students_clean_parent_occs.do"
do "${dodir_par_stu}/7_ps_students_drop_vars.do"

// 5. Clean the Parents Data
do "${dodir_par_par}/1_ps_parents_anonymize.do"
do "${dodir_par_par}/2_ps_parents_remove_duplicates.do"
do "${dodir_par_par}/3_ps_parents_clean_beliefs.do"
do "${dodir_par_par}/4_ps_parents_clean_other.do"
do "${dodir_par_par}/5_ps_parents_merge_chars.do"
do "${dodir_par_par}/6_ps_parents_clean_parent_occs.do"
do "${dodir_par_par}/7_ps_parents_drop_vars.do"

// 6. Done
log close
