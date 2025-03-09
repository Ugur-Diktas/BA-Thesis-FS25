********************************************************************************
* 9_ps_students_clean_parent_occs.do
* ------------------------------------------------------------------------------
* Data needed: 8_ps_students.dta
* Data output: 9_ps_students.dta
* Purpose:
*   - Creates standardized parent occupation variables
*   - Handles the mapping to ISCED codes with minimal processing
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************
clear all
set more off
version 18.0

if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/9_ps_students_clean_parent_occs.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Parent Occupations"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// 1. LOAD AND PREPARE DATASET
********************************************************************************
di as txt "----- Loading dataset: 8_ps_students.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Students/8_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/8_ps_students.dta"
    di as error "Run 8_ps_students_merge_chars.do first."
    exit 601
}

use "${processed_data}/PS_Students/8_ps_students.dta", clear
di as txt "Loaded dataset with `c(N)' observations and `c(k)' variables."

// Initialize final variables
di as txt "Initializing parent occupation variables..."

capture confirm variable mother_occ_isced6_final
if _rc {
    gen mother_occ_isced6_final = ""
    label var mother_occ_isced6_final "Mother's occupation field (cleaned)"
}

capture confirm variable father_occ_isced6_final
if _rc {
    gen father_occ_isced6_final = ""
    label var father_occ_isced6_final "Father's occupation field (cleaned)"
}

// Initialize numeric ISCED fields
capture confirm variable mother_isced_num
if _rc {
    gen mother_isced_num = .
    label var mother_isced_num "ISCED field code for mother"
}

capture confirm variable father_isced_num
if _rc {
    gen father_isced_num = .
    label var father_isced_num "ISCED field code for father"
}

********************************************************************************
// 2. DIRECT ISCED CODE ASSIGNMENT
********************************************************************************
di as txt "----- Assigning ISCED codes directly -----"

// Check if parent occupation variables exist
local mother_occ_exists = 0
capture confirm variable mother_occ
if !_rc {
    local mother_occ_exists = 1
    di as txt "Found mother_occ variable."
}

local father_occ_exists = 0
capture confirm variable father_occ
if !_rc {
    local father_occ_exists = 1
    di as txt "Found father_occ variable."
}

// Process mother occupations if available
if `mother_occ_exists' {
    di as txt "Processing mother occupations from variable: mother_occ"
    
    // Assign ISCED codes based on standard categories
    replace mother_occ_isced6_final = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
         if mother_occ == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Dienstleistungen und Detailhandel" ///
         if mother_occ == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Wirtschaft, Verwaltung und Recht" ///
         if mother_occ == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
         if mother_occ == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
         if (mother_occ == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
            mother_occ == "Sozialwissenschaften, Journalismus und Geisteswissenschaften") & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
         if mother_occ == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" & missing(mother_occ_isced6_final)
    
    // Common special cases
    replace mother_occ_isced6_final = "Hausfrau/mann" if inlist(lower(mother_occ), "hausfrau", "hausmann", "hausfrau/mann") & missing(mother_occ_isced6_final)
    
    // Count how many were directly mapped
    count if !missing(mother_occ_isced6_final) & !missing(mother_occ)
    local n_mapped = r(N)
    count if missing(mother_occ_isced6_final) & !missing(mother_occ)
    local n_unmapped = r(N)
    
    di as txt "Direct mapping for mother occupations: `n_mapped' mapped, `n_unmapped' unmapped"
}
else {
    di as txt "Variable mother_occ not found, skipping mother occupation processing."
}

// Process father occupations if available
if `father_occ_exists' {
    di as txt "Processing father occupations from variable: father_occ"
    
    // Assign ISCED codes based on standard categories
    replace father_occ_isced6_final = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
         if father_occ == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Dienstleistungen und Detailhandel" ///
         if father_occ == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Wirtschaft, Verwaltung und Recht" ///
         if father_occ == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
         if father_occ == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
         if (father_occ == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
            father_occ == "Sozialwissenschaften, Journalismus und Geisteswissenschaften") & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
         if father_occ == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" & missing(father_occ_isced6_final)
    
    // Common special cases
    replace father_occ_isced6_final = "Hausfrau/mann" if inlist(lower(father_occ), "hausfrau", "hausmann", "hausfrau/mann") & missing(father_occ_isced6_final)
    
    // Count how many were directly mapped
    count if !missing(father_occ_isced6_final) & !missing(father_occ)
    local n_mapped = r(N)
    count if missing(father_occ_isced6_final) & !missing(father_occ)
    local n_unmapped = r(N)
    
    di as txt "Direct mapping for father occupations: `n_mapped' mapped, `n_unmapped' unmapped"
}
else {
    di as txt "Variable father_occ not found, skipping father occupation processing."
}

********************************************************************************
// 3. CREATE NUMERIC ISCED FIELDS
********************************************************************************
di as txt "----- Creating numeric ISCED fields -----"

// Create numeric ISCED fields
foreach parent in mother father {
    replace `parent'_isced_num = 1 if `parent'_occ_isced6_final == "Gesundheit, Pflege, Betreuung und Ausbildung"
    replace `parent'_isced_num = 2 if `parent'_occ_isced6_final == "Dienstleistungen und Detailhandel"
    replace `parent'_isced_num = 3 if `parent'_occ_isced6_final == "Wirtschaft, Verwaltung und Recht"
    replace `parent'_isced_num = 4 if `parent'_occ_isced6_final == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"
    replace `parent'_isced_num = 5 if `parent'_occ_isced6_final == "Sozialwissenschaften, Journalismus und Geisteswissenschaften"
    replace `parent'_isced_num = 6 if `parent'_occ_isced6_final == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin"
    replace `parent'_isced_num = -14 if `parent'_occ_isced6_final == "Hausfrau/mann"
    replace `parent'_isced_num = -2 if `parent'_occ_isced6_final == "None"
    replace `parent'_isced_num = -8 if `parent'_occ_isced6_final == "Doesn't know"
}

// Define value labels for ISCED fields
capture label define isced_field_lbl ///
    1 "Gesundheit, Pflege, Betreuung und Ausbildung" ///
    2 "Dienstleistungen und Detailhandel" ///
    3 "Wirtschaft, Verwaltung und Recht" ///
    4 "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
    5 "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
    6 "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
    -14 "Hausfrau/mann" ///
    -2 "None" ///
    -8 "Doesn't know", replace

label values mother_isced_num father_isced_num isced_field_lbl

// Count the distribution of mother's occupations
di as txt "Distribution of mother's occupations by ISCED field:"
tab mother_isced_num

// Count the distribution of father's occupations
di as txt "Distribution of father's occupations by ISCED field:"
tab father_isced_num

********************************************************************************
// 4. EXPORT UNMAPPED OCCUPATIONS FOR REFERENCE
********************************************************************************
di as txt "----- Exporting unmapped occupations for reference -----"

// Setup for unmapped export
tempfile unmapped_combined

// Export unmapped mother occupations
capture confirm variable mother_occ
if !_rc {
    preserve
        keep if !missing(mother_occ) & missing(mother_occ_isced6_final)
        if _N > 0 {
            di as txt "Found `=_N' unmapped mother occupations, exporting."
            keep ResponseId mother_occ
            gen occ_type = "mother"
            rename mother_occ parent_occ
            
            save `unmapped_combined', replace
        }
        else {
            di as txt "No unmapped mother occupations found."
        }
    restore
}

// Export unmapped father occupations
capture confirm variable father_occ
if !_rc {
    preserve
        keep if !missing(father_occ) & missing(father_occ_isced6_final)
        if _N > 0 {
            di as txt "Found `=_N' unmapped father occupations, exporting."
            keep ResponseId father_occ
            gen occ_type = "father"
            rename father_occ parent_occ
            
            // Check if we have mother occupations to append
            capture confirm file `unmapped_combined'
            if !_rc {
                // We have mother occupations, append father occupations
                tempfile father_unmapped
                save `father_unmapped'
                
                use `unmapped_combined', clear
                append using `father_unmapped'
                save `unmapped_combined', replace
            }
            else {
                // No mother occupations, save father occupations as main file
                save `unmapped_combined', replace
            }
        }
        else {
            di as txt "No unmapped father occupations found."
        }
    restore
}

// Export the combined unmapped occupations if any
capture confirm file `unmapped_combined'
if !_rc {
    preserve
        use `unmapped_combined', clear
        
        // Ensure processed_data/PS_Students directory exists
        capture mkdir "${processed_data}/PS_Students"
        
        // Export to Excel
        capture export excel ResponseId occ_type parent_occ using "${processed_data}/PS_Students/unmapped_occupations.xlsx", ///
            firstrow(variables) replace
            
        if !_rc {
            di as txt "Exported unmapped occupations to ${processed_data}/PS_Students/unmapped_occupations.xlsx"
        }
        else {
            di as error "Warning: Could not export to Excel. Error code: `_rc'"
        }
    restore
}
else {
    di as txt "No unmapped occupations to export."
}

********************************************************************************
// 5. SAVE FINAL DATASET
********************************************************************************
di as txt "----- Saving final dataset -----"

// Final verification
count if !missing(mother_occ_isced6_final)
di as txt "Mother occupations with ISCED codes: `r(N)'"
count if !missing(father_occ_isced6_final)
di as txt "Father occupations with ISCED codes: `r(N)'"

// Compress and save final dataset
compress
save "${processed_data}/PS_Students/9_ps_students.dta", replace

// Final report
di as txt "Cleaned parent occupations dataset saved to: ${processed_data}/PS_Students/9_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Parent Occupations"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off