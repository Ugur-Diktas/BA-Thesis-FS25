/*==============================================================================
# edge_case_tests.do
# Purpose: Test edge cases and potential issues in the data cleaning pipeline
# Author: Based on UGUR DIKTAS and JELKE CLARYSSE's data cleaning code
# Date: March 2025
# 
# This do-file runs specialized tests to check for:
# 1. String truncation issues in variable processing
# 2. Missing value handling
# 3. Duplicate resolution verification
# 4. Encoded variable consistency
# 5. Merge issues and orphaned observations
# 6. Data type conversion problems
# 
# Usage: 
# 1. Just run this file from Stata: do edge_case_tests.do
#    (Root path will be automatically determined based on username)
# 
# The results will be saved in a log file in the tests/logs directory
==============================================================================*/

// Auto-determine root path based on username (same as in 1_master.do)
if c(username) == "jelkeclarysse" {
    global root "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}
else if c(username) == "ugurdiktas" {
    global root "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
}
else {
    // Fallback to current directory if username not recognized
    global root "`c(pwd)'"
}

// Setup
clear all
set more off
version 18.0

// Create logs directory if it doesn't exist
quietly {
    local test_dir "${root}/tests"
    shell mkdir "${test_dir}" 2>nul
    shell mkdir "${test_dir}/logs" 2>nul
    
    local log_timestamp = subinstr(subinstr("`c(current_date)'", " ", "", .), ":", "", .) + "_" + subinstr("`c(current_time)'", ":", "", .)
    local log_file "${test_dir}/logs/edge_case_tests_`log_timestamp'.log"
}

// Start logging
log using "`log_file'", replace

// Display header
display as text _newline(2)
display as text "=================================================================="
display as text "  STATA DATA CLEANING EDGE CASE TESTS"
display as text "  Started: `c(current_date)' `c(current_time)'"
display as text "  Stata version: `c(stata_version)'"
display as text "=================================================================="
display as text _newline(2)

// Initialize results storage
tempfile results_file
tempname results_handle
postfile `results_handle' str80 test_category str80 test_name str20 result str255 notes ///
    using `results_file', replace

// Source globals for consistent paths
quietly do "${root}/2_code/2_globals.do"

/*==============================================================================
# 1. STRING TRUNCATION TESTS
# Check for issues related to string truncation in occupation and location variables
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: STRING TRUNCATION ISSUES"
display as text "=================================================================="

capture {
    // Check for potentially truncated occupation strings
    local test_name "Occupation string truncation"
    local category "String Truncation"
    local issue_found = 0
    local notes = ""
    
    // Try to find the occupation variables in the cleaned data
    use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
    
    // Test variable 'plan' if it exists
    capture confirm variable plan
    if _rc == 0 {
        // Check for strings that might be truncated (ending with ...)
        count if regexm(plan, "\.\.\.$")
        if r(N) > 0 {
            local issue_found = 1
            local notes = "`notes' Found `r(N)' potentially truncated plan strings. "
        }
        
        // Check for very long strings that might indicate truncation elsewhere
        summarize length(plan)
        if r(max) >= 240 {
            local issue_found = 1
            local notes = "`notes' Found plan strings approaching max length (`r(max)'/244). "
        }
    }
    
    // Check other occupation-related variables
    foreach var of varlist *_occ* {
        capture confirm string variable `var'
        if _rc == 0 {
            // Check for strings that might be truncated
            count if regexm(`var', "\.\.\.$")
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Found `r(N)' potentially truncated strings in `var'. "
            }
            
            // Check for very long strings
            summarize length(`var')
            if r(max) >= 240 {
                local issue_found = 1
                local notes = "`notes' Found `var' strings approaching max length (`r(max)'/244). "
            }
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential string truncation issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No string truncation issues found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: String truncation test failed with code `_rc'"
    post `results_handle' ("String Truncation") ("Occupation string truncation") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 2. MISSING VALUE HANDLING
# Check for issues related to missing value handling
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: MISSING VALUE HANDLING"
display as text "=================================================================="

capture {
    // Test for potential issues with missing value handling
    local test_name "Missing value handling"
    local category "Missing Values"
    local issue_found = 0
    local notes = ""
    
    // Load the final student dataset
    use "${processed_data}/PS_Students/ps_stu_final.dta", clear
    
    // Check for missing values in key variables
    foreach var of varlist female contract {
        capture confirm numeric variable `var'
        if _rc == 0 {
            count if missing(`var')
            local miss_count = r(N)
            local miss_pct = `miss_count' / _N * 100
            
            if `miss_pct' > 5 {
                local issue_found = 1
                local notes = "`notes' `var': `miss_count' missing values (`miss_pct'%). "
            }
        }
    }
    
    // Check for variables that should never be missing
    capture confirm variable ResponseId
    if _rc == 0 {
        count if missing(ResponseId)
        if r(N) > 0 {
            local issue_found = 1
            local notes = "`notes' Found `r(N)' missing ResponseId values. "
        }
    }
    
    // Check for strange patterns in missing values
    // E.g., all values missing for certain groups
    capture confirm numeric variable female
    if _rc == 0 {
        foreach var of varlist * {
            if "`var'" != "female" & "`var'" != "ResponseId" {
                capture confirm numeric variable `var'
                if _rc == 0 {
                    count if !missing(`var') & female == 1
                    local nonmiss_female = r(N)
                    count if !missing(`var') & female == 0
                    local nonmiss_male = r(N)
                    count if female == 1
                    local total_female = r(N)
                    count if female == 0
                    local total_male = r(N)
                    
                    // Calculate non-missing percentages by gender
                    if `total_female' > 0 & `total_male' > 0 {
                        local pct_female = `nonmiss_female' / `total_female' * 100
                        local pct_male = `nonmiss_male' / `total_male' * 100
                        
                        // Check for large disparities in missingness by gender
                        local diff = abs(`pct_female' - `pct_male')
                        if `diff' > 20 {
                            local issue_found = 1
                            local notes = "`notes' Var `var' has gender-biased missingness (F:`pct_female'%, M:`pct_male'%). "
                        }
                    }
                }
            }
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential missing value issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No concerning missing value patterns found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Missing value test failed with code `_rc'"
    post `results_handle' ("Missing Values") ("Missing value handling") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 3. DUPLICATE RESOLUTION VERIFICATION
# Check that duplicate records were properly resolved
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: DUPLICATE RESOLUTION"
display as text "=================================================================="

capture {
    // Check for remaining duplicates
    local test_name "Duplicate resolution"
    local category "Duplicates"
    local issue_found = 0
    local notes = ""
    
    // Check student dataset
    use "${processed_data}/PS_Students/ps_stu_final.dta", clear
    
    // Check duplicates on ResponseId
    duplicates report ResponseId
    if r(unique_value) < r(N) {
        local issue_found = 1
        local notes = "`notes' Found `=r(N)-r(unique_value)' duplicate ResponseId values in student dataset. "
    }
    
    // Check parent dataset if it exists
    capture confirm file "${processed_data}/PS_Parents/ps_parents_final.dta"
    if _rc == 0 {
        use "${processed_data}/PS_Parents/ps_parents_final.dta", clear
        
        // Check duplicates on ResponseId
        duplicates report ResponseId
        if r(unique_value) < r(N) {
            local issue_found = 1
            local notes = "`notes' Found `=r(N)-r(unique_value)' duplicate ResponseId values in parent dataset. "
        }
    }
    else {
        // Try intermediate parent dataset
        capture confirm file "${processed_data}/PS_Parents/temp_parents_step2.dta"
        if _rc == 0 {
            use "${processed_data}/PS_Parents/temp_parents_step2.dta", clear
            
            // Check duplicates on ResponseId
            duplicates report ResponseId
            if r(unique_value) < r(N) {
                local issue_found = 1
                local notes = "`notes' Found `=r(N)-r(unique_value)' duplicate ResponseId values in parent intermediate dataset. "
            }
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential duplicate resolution issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No duplicate issues found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No duplicate issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Duplicate resolution test failed with code `_rc'"
    post `results_handle' ("Duplicates") ("Duplicate resolution") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 4. ENCODED VARIABLE CONSISTENCY
# Check that encoded variables have consistent values
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: ENCODED VARIABLE CONSISTENCY"
display as text "=================================================================="

capture {
    // Check encoded variables for consistency
    local test_name "Encoded variable consistency"
    local category "Encoded Variables"
    local issue_found = 0
    local notes = ""
    
    // Load the student dataset
    use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
    
    // Check track variable if it exists
    capture confirm variable track
    if _rc == 0 {
        // Check if track has valid values (should be 1-6)
        count if !inrange(track, 1, 6) & !missing(track)
        if r(N) > 0 {
            local issue_found = 1
            local notes = "`notes' Found `r(N)' track values outside the expected range (1-6). "
        }
        
        // Check if track has value labels
        local has_labels = 0
        local track_lblname : value label track
        if "`track_lblname'" != "" {
            local has_labels = 1
        }
        
        if `has_labels' == 0 {
            local issue_found = 1
            local notes = "`notes' Track variable missing value labels. "
        }
    }
    
    // Check other encoded variables
    foreach var in home_sit_stu {
        capture confirm variable `var'
        if _rc == 0 {
            // Check if variable has value labels
            local has_labels = 0
            local var_lblname : value label `var'
            if "`var_lblname'" != "" {
                local has_labels = 1
            }
            
            if `has_labels' == 0 {
                local issue_found = 1
                local notes = "`notes' Variable `var' missing value labels. "
            }
        }
    }
    
    // Check belief variables if they exist
    foreach var in belief_fit_occ2 belief_fit_occ3 belief_fit_occ4 belief_fit_occ5 belief_fit_occ6 belief_fit_occ7 {
        capture confirm variable `var'
        if _rc == 0 {
            // Check if values are within expected range (1-5)
            count if !inrange(`var', 1, 5) & !missing(`var')
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Found `r(N)' values in `var' outside the expected range (1-5). "
            }
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential encoded variable consistency issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No encoded variable consistency issues found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Encoded variable test failed with code `_rc'"
    post `results_handle' ("Encoded Variables") ("Encoded variable consistency") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 5. MERGE ISSUES AND ORPHANED OBSERVATIONS
# Check for issues related to merges in the pipeline
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: MERGE ISSUES"
display as text "=================================================================="

capture {
    // Test for potential orphaned observations after merges
    local test_name "Merge orphans"
    local category "Merge Issues"
    local issue_found = 0
    local notes = ""
    
    // Check if we can find evidence of merges in PS_Students/8_ps_students_merge_chars.do
    local merge_dofile "${root}/2_code/PS_Students/8_ps_students_merge_chars.do"
    capture confirm file "`merge_dofile'"
    if _rc == 0 {
        // Load the student dataset before merge
        capture confirm file "${processed_data}/PS_Students/ps_stu_cleaned.dta"
        if _rc == 0 {
            use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
            count
            local before_merge_count = r(N)
            
            // Load the student dataset after merge
            capture confirm file "${processed_data}/PS_Students/ps_stu_chars_merged.dta"
            if _rc == 0 {
                use "${processed_data}/PS_Students/ps_stu_chars_merged.dta", clear
                count
                local after_merge_count = r(N)
                
                // Compare counts
                if `after_merge_count' < `before_merge_count' {
                    local issue_found = 1
                    local notes = "`notes' Found `=`before_merge_count'-`after_merge_count'' potentially lost observations after merge in char_merged dataset. "
                }
            }
        }
    }
    
    // Check final dataset vs cleaned dataset
    capture confirm file "${processed_data}/PS_Students/ps_stu_cleaned.dta"
    capture confirm file "${processed_data}/PS_Students/ps_stu_final.dta"
    if _rc == 0 {
        use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
        count
        local cleaned_count = r(N)
        
        use "${processed_data}/PS_Students/ps_stu_final.dta", clear
        count
        local final_count = r(N)
        
        // Compare counts
        if `final_count' < `cleaned_count' * 0.9 {
            local issue_found = 1
            local notes = "`notes' Found substantial observation loss between cleaned and final datasets (Cleaned: `cleaned_count', Final: `final_count'). "
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential merge issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No concerning merge issues found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Merge issues test failed with code `_rc'"
    post `results_handle' ("Merge Issues") ("Merge orphans") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 6. DATA TYPE CONVERSION PROBLEMS
# Check for issues related to data type conversions
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: DATA TYPE CONVERSION"
display as text "=================================================================="

capture {
    // Test for data type conversion problems
    local test_name "Data type conversion"
    local category "Data Types"
    local issue_found = 0
    local notes = ""
    
    // Load the final student dataset
    use "${processed_data}/PS_Students/ps_stu_final.dta", clear
    
    // Check key numeric variables
    foreach var in contract female {
        capture confirm numeric variable `var'
        if _rc != 0 {
            local issue_found = 1
            local notes = "`notes' Variable `var' is not numeric as expected. "
        }
    }
    
    // Check for numeric variables where the values suggest they should be string (e.g., codes stored as numbers)
    foreach var of varlist * {
        capture confirm numeric variable `var'
        if _rc == 0 {
            if inlist("`var'", "ResponseId") {
                local issue_found = 1
                local notes = "`notes' Key ID variable `var' is numeric but should be string. "
            }
        }
    }
    
    // Check for string variables that should be numeric
    foreach var of varlist * {
        capture confirm string variable `var'
        if _rc == 0 {
            // Check if the string contains only numbers
            cap gen is_all_numeric = real(`var') != . if !missing(`var')
            if _rc == 0 {
                count if is_all_numeric == 1
                local all_numeric_count = r(N)
                count if !missing(`var')
                local nonmissing_count = r(N)
                
                if `nonmissing_count' > 0 & `all_numeric_count' / `nonmissing_count' > 0.9 {
                    // More than 90% of values are numeric - this might need to be a numeric variable
                    local issue_found = 1
                    local notes = "`notes' Variable `var' is string but mostly contains only numbers. "
                }
                
                drop is_all_numeric
            }
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential data type conversion issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "No data type conversion issues found"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Data type conversion test failed with code `_rc'"
    post `results_handle' ("Data Types") ("Data type conversion") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 7. SANITY CHECKS ON FINAL VARIABLES
# Check that key variables have sensible values
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: VARIABLE SANITY CHECKS"
display as text "=================================================================="

capture {
    // Test for data sanity and range issues
    local test_name "Variable sanity checks"
    local category "Variable Sanity"
    local issue_found = 0
    local notes = ""
    
    // Load the final student dataset
    use "${processed_data}/PS_Students/ps_stu_final.dta", clear
    
    // Check binary variables
    foreach var in female contract {
        capture confirm numeric variable `var'
        if _rc == 0 {
            // Check if values are only 0, 1, or missing
            count if !inlist(`var', 0, 1, .)
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Binary variable `var' has values other than 0, 1, or missing. "
            }
        }
    }
    
    // Check age variable if it exists
    capture confirm variable age
    if _rc == 0 {
        capture confirm numeric variable age
        if _rc == 0 {
            // Age should be reasonable (we expect students, so 10-25 range)
            count if !inrange(age, 10, 25) & !missing(age)
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Age variable has `r(N)' values outside reasonable range (10-25). "
            }
        }
    }
    
    // Check variables with expected patterns
    capture confirm variable sit
    if _rc == 0 {
        capture confirm numeric variable sit
        if _rc == 0 {
            // Check if sit has expected values (1, 2, 4)
            count if !inlist(sit, 1, 2, 4) & !missing(sit)
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Variable 'sit' has `r(N)' unexpected values (not 1, 2, or 4). "
            }
        }
    }
    
    // Check canton variable if it exists
    capture confirm variable canton
    if _rc == 0 {
        capture confirm string variable canton
        if _rc == 0 {
            // Check if canton has valid Swiss canton names/abbreviations
            local valid_cantons `""Zürich" "Bern" "Luzern" "Uri" "Schwyz" "Obwalden" "Nidwalden" "Glarus" "Zug" "Freiburg" "Solothurn" "Basel-Stadt" "Basel-Landschaft" "Schaffhausen" "Appenzell Ausserrhoden" "Appenzell Innerrhoden" "St. Gallen" "Graubünden" "Aargau" "Thurgau" "Tessin" "Waadt" "Wallis" "Neuenburg" "Genf" "Jura" "ZH" "BE" "LU" "UR" "SZ" "OW" "NW" "GL" "ZG" "FR" "SO" "BS" "BL" "SH" "AR" "AI" "SG" "GR" "AG" "TG" "TI" "VD" "VS" "NE" "GE" "JU" "Grigioni" "Basilea Città" "Ticino""'
            
            gen valid_canton = 0
            foreach c of local valid_cantons {
                replace valid_canton = 1 if canton == "`c'"
            }
            
            count if valid_canton == 0 & !missing(canton)
            if r(N) > 0 {
                local issue_found = 1
                local notes = "`notes' Found `r(N)' potentially invalid canton values. "
            }
            
            drop valid_canton
        }
    }
    
    if `issue_found' == 1 {
        display as error "WARNING: Potential variable sanity issues found"
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes'")
    }
    else {
        display as text "All variables pass sanity checks"
        post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No issues detected")
    }
}

if _rc != 0 {
    display as error "ERROR: Variable sanity test failed with code `_rc'"
    post `results_handle' ("Variable Sanity") ("Variable sanity checks") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# 8. LOG FILE ANALYSIS
# Check log files for errors and warnings
==============================================================================*/
display as text _newline(2)
display as text "=================================================================="
display as text "  TEST CATEGORY: LOG FILE ANALYSIS"
display as text "=================================================================="

capture {
    // Analyze log files for errors and warnings
    local test_name "Log file errors"
    local category "Log Analysis"
    local issue_found = 0
    local notes = ""
    
    // Check if log directory exists
    local log_dir "${root}/3_logfiles"
    capture confirm file "`log_dir'"
    if _rc != 0 {
        display as error "ERROR: Log directory not found at `log_dir'"
        post `results_handle' ("`category'") ("`test_name'") ("ERROR") ("Log directory not found")
        exit
    }
    
    // Get list of log files
    local log_files : dir "`log_dir'" files "*.log"
    local log_files : list sort log_files
    
    // Create a temporary file to store error lines
    tempfile error_lines
    tempname error_handle
    file open `error_handle' using "`error_lines'", write replace
    
    // Count files with errors
    local error_file_count = 0
    local warning_file_count = 0
    
    // Check each log file for errors and warnings
    foreach logfile of local log_files {
        local full_path "`log_dir'/`logfile'"
        
        // Use findstr (Windows) or grep (Linux/Mac) to search for error patterns
        if "`c(os)'" == "Windows" {
            quietly shell findstr /i "error invalid syntax type mismatch already defined not found" "`full_path'" > search_results.txt
        }
        else {
            quietly shell grep -i -E "error|invalid|syntax|type mismatch|already defined|not found" "`full_path'" > search_results.txt
        }
        
        // Check if search found anything
        capture confirm file "search_results.txt"
        if _rc == 0 {
            // Check file size to see if anything was found
            quietly shell dir search_results.txt
            if r(filesize) > 0 {
                local ++error_file_count
                file write `error_handle' "ERRORS IN: `logfile'" _n
                file write `error_handle' "-----------------------" _n
                
                // Append error lines to our temp file
                file close `error_handle'
                quietly shell type search_results.txt >> "`error_lines'"
                file open `error_handle' using "`error_lines'", write append
                file write `error_handle' _n _n
                
                local issue_found = 1
                local notes = "`notes' Found errors in log file: `logfile'. "
            }
        }
        
        // Search for warnings
        if "`c(os)'" == "Windows" {
            quietly shell findstr /i "warning caution attention note" "`full_path'" > warning_results.txt
        }
        else {
            quietly shell grep -i -E "warning|caution|attention|note" "`full_path'" > warning_results.txt
        }
        
        // Check if search found any warnings
        capture confirm file "warning_results.txt"
        if _rc == 0 {
            // Check file size to see if anything was found
            quietly shell dir warning_results.txt
            if r(filesize) > 0 {
                local ++warning_file_count
            }
        }
        
        // Clean up temporary search files
        capture erase search_results.txt
        capture erase warning_results.txt
    }
    
    file close `error_handle'
    
    if `issue_found' == 1 {
        display as error "WARNING: Found errors in `error_file_count' log files"
        if `warning_file_count' > 0 {
            display as error "Additionally found warnings in `warning_file_count' log files"
        }
        
        // Display excerpt of errors found
        display as text _newline
        display as text "Error excerpt (full details in results file):"
        display as text "-----------------------------------------"
        type "`error_lines'", lines(10)
        display as text "-----------------------------------------"
        
        post `results_handle' ("`category'") ("`test_name'") ("WARNING") ("`notes' Errors in `error_file_count' files. Warnings in `warning_file_count' files.")
    }
    else {
        if `warning_file_count' > 0 {
            display as text "No errors found, but warnings present in `warning_file_count' log files"
            post `results_handle' ("`category'") ("`test_name'") ("PARTIAL") ("No errors found, but warnings present in `warning_file_count' log files")
        }
        else {
            display as text "No errors or warnings found in log files"
            post `results_handle' ("`category'") ("`test_name'") ("PASS") ("No errors or warnings detected in log files")
        }
    }
}

if _rc != 0 {
    display as error "ERROR: Log file analysis failed with code `_rc'"
    post `results_handle' ("Log Analysis") ("Log file errors") ("ERROR") ("Test execution failed")
}

/*==============================================================================
# RESULTS AND SUMMARY
==============================================================================*/
// Load results
use `results_file', clear

// Display results
display as text _newline(2)
display as text "=================================================================="
display as text "  EDGE CASE TEST RESULTS SUMMARY"
display as text "=================================================================="

// Generate summary stats
count
local total_tests = r(N)

count if result == "PASS"
local pass_count = r(N)

count if result == "FAIL"
local fail_count = r(N)

count if result == "ERROR"
local error_count = r(N)

count if result == "WARNING" | result == "PARTIAL"
local warning_count = r(N)

local pass_rate = `pass_count' / `total_tests' * 100

// Display summary
display as text _newline
display as text "  Total tests:  `total_tests'"
display as text "  Passed:       `pass_count' (`pass_rate'%)"
display as text "  Failed:       `fail_count'"
display as text "  Errors:       `error_count'"
display as text "  Warnings:     `warning_count'"
display as text "=================================================================="

// Present detailed results
display as text _newline
display as text "DETAILED RESULTS:"
display as text "--------------------------------------------------------------------"
list test_category test_name result notes, sepby(test_category) abbreviate(40)

// Save results to Excel
export excel using "${root}/tests/edge_case_results_`log_timestamp'.xlsx", firstrow(variables) replace

// Display completion message
display as text _newline(2)
display as text "=================================================================="
display as text "  EDGE CASE TEST RUN COMPLETE"
display as text "  Results saved to: ${root}/tests/edge_case_results_`log_timestamp'.xlsx"
display as text "  Log saved to: `log_file'"
display as text "=================================================================="

log close