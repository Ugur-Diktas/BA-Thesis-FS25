********************************************************************************
* 1_master.do
* ------------------------------------------------------------------------------
* Purpose:
*   - Master do-file that runs all cleaning do-files in order for Students and Parents.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

clear all
set more off

// 1. Define your root path based on username
if c(username) == "jelkeclarysse" {
    global root "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}
else if c(username) == "ugurdiktas" {
    global root "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}
else {
    di as error "ERROR: Unknown username. Please update username paths in 1_master.do"
    exit 601
}

// Try to change to that directory as a test
capture cd "${root}"
if _rc {
    di as error "ERROR: Root path not found or not accessible: ${root}"
    exit 601
}

// Return to current directory (probably unnecessary since we want to be in root)
cd "${root}"

// 2. Log settings
cap log close

// 3. Run the globals file
qui do "2_code/2_globals.do"
di as text "Global variables loaded successfully."

// 4. Clean the Students Data
local student_steps 10
local student_errors 0
forvalues i = 1/`student_steps' {
    di _newline
    di as text "======================================================="
    di as text "Running step `i' of `student_steps' for Students data"
    di as text "======================================================="
    
    // List all do-files that match the pattern and execute the first one found
    local files : dir "${dodir_par_stu}" files "`i'_ps_students_*.do"
    local found_file = 0
    
    foreach file of local files {
        // Only run the first matching file
        if `found_file' == 0 {
            di as text "Running file: ${dodir_par_stu}/`file'"
            capture noisily do "${dodir_par_stu}/`file'"
            if _rc {
                di as error "ERROR: Step `i' failed for Students data with error code: " _rc
                local student_errors = `student_errors' + 1
            }
            else {
                di as text "Step `i' completed successfully for Students data."
            }
            local found_file = 1
        }
    }
    
    // If no matching files found
    if `found_file' == 0 {
        di as error "ERROR: No file found for step `i' in ${dodir_par_stu}"
        local student_errors = `student_errors' + 1
    }
}

// 5. Clean the Parents Data
local parent_steps 10
local parent_errors 0
forvalues i = 1/`parent_steps' {
    di _newline
    di as text "======================================================="
    di as text "Running step `i' of `parent_steps' for Parents data"
    di as text "======================================================="
    
    // List all do-files that match the pattern and execute the first one found
    local files : dir "${dodir_par_par}" files "`i'_ps_parents_*.do"
    local found_file = 0
    
    foreach file of local files {
        // Only run the first matching file
        if `found_file' == 0 {
            di as text "Running file: ${dodir_par_par}/`file'"
            capture noisily do "${dodir_par_par}/`file'"
            if _rc {
                di as error "ERROR: Step `i' failed for Parents data with error code: " _rc
                local parent_errors = `parent_errors' + 1
            }
            else {
                di as text "Step `i' completed successfully for Parents data."
            }
            local found_file = 1
        }
    }
    
    // If no matching files found
    if `found_file' == 0 {
        di as error "ERROR: No file found for step `i' in ${dodir_par_par}"
        local parent_errors = `parent_errors' + 1
    }
}

// 6. Summary
di _newline
di as text "======================================================="
di as text "CLEANING PIPELINE SUMMARY"
di as text "======================================================="
di as text "Students cleaning: `student_steps' steps, `student_errors' errors"
di as text "Parents cleaning: `parent_steps' steps, `parent_errors' errors"

if `student_errors' == 0 & `parent_errors' == 0 {
    di as text "All cleaning do-files have been run successfully!"
}
else {
    di as error "WARNING: Some cleaning steps failed. Check the log for details."
}

di "All cleaning do-files have been run successfully!"
