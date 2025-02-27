********************************************************************************
// 1_master.do
// Purpose : Master do-file that runs all cleaning do-files in order
//           for PS_Students and PS_Parents.
//
// Usage   : 
//   1) Place your raw data files in 1_data/raw
//   2) Then just run this 1_master.do to produce anonymised & cleaned data.
//	 !! Before runtime, please make sure to cd your Stata terminal lsto root
//
// Author  : Ugur Diktas-Jelke Clarysse, BA Thesis FS25, 25.02.2025
********************************************************************************

clear all
set more off

// 1. Define your root path

if c(username) == "jelkeclarysse" {
    global root "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}

if c(username) == "ugurdiktas" {
    global root "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}

cd "${root}"

// 2. Log settings

cap log close
log using "3_logfiles/1_master.log", replace

// 3. Run the globals file

quietly do "2_code/2_globals.do"

// 4. Clean the Students Data
do "${dodir_par_stu}/1_ps_students_anonymize.do"
do "${dodir_par_stu}/2_ps_students_remove_duplicates.do"
do "${dodir_par_stu}/3_ps_students_clean_relabeling.do"
do "${dodir_par_stu}/4_ps_students_clean_beliefs.do"
do "${dodir_par_stu}/5_ps_students_clean_motivations.do"
do "${dodir_par_stu}/6_ps_students_clean_other.do"
do "${dodir_par_stu}/7_ps_students_merge_chars.do"
do "${dodir_par_stu}/8_ps_students_clean_parent_occs.do"
do "${dodir_par_stu}/9_ps_students_drop_vars.do"

// 5. Clean the Parents Data
do "${dodir_par_par}/1_ps_parents_anonymize.do"
do "${dodir_par_par}/2_ps_parents_remove_duplicates.do"
do "${dodir_par_par}/3_ps_parents_clean_beliefs.do"
do "${dodir_par_par}/4_ps_parents_clean_other.do"
do "${dodir_par_par}/5_ps_parents_merge_chars.do"
do "${dodir_par_par}/6_ps_parents_clean_parent_occs.do"
do "${dodir_par_par}/7_ps_parents_drop_vars.do"

di "All cleaning do-files have been run successfully!"

// 6. Done
log close
