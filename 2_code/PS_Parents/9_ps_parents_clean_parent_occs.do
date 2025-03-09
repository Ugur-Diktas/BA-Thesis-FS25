********************************************************************************
* 9_ps_parents_clean_parent_occs.do
* ------------------------------------------------------------------------------
* Data needed: 8_ps_parents.dta
* Data output: 9_ps_parents.dta
* Purpose:
*   - Creates standardized parent occupation variables
*   - Handles the mapping to ISCED codes with minimal processing
*   - Handles the specific structure of parent datasets where occupations
*     may be stored in different variables based on parent type
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
log using "${dodir_log}/9_ps_parents_clean_parent_occs.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Clean Parent Occupations"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// 1. LOAD AND PREPARE DATASET
********************************************************************************
di as txt "----- Loading dataset: 8_ps_parents.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/8_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/8_ps_parents.dta"
    di as error "Run 8_ps_parents_merge_chars.do first."
    exit 601
}

use "${processed_data}/PS_Parents/8_ps_parents.dta", clear
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
// 2. DETECT AND STANDARDIZE PARENT OCCUPATION VARIABLES
********************************************************************************
di as txt "----- Detecting parent occupation variables -----"

// In parent dataset, occupation might be stored in different ways:
// 1. As mother_occ/father_occ directly
// 2. As own_occupation/partner_occupation depending on Parent_type_
// 3. As some other variable naming convention

// Check if we have direct mother/father variables
local has_mother_occ = 0
local has_father_occ = 0

// Check for common mothers' occupation variables
foreach var in mother_occ motherocc mother_occupation motheroccupation mom_occ momocc {
    capture confirm variable `var'
    if !_rc {
        di as txt "Found mother occupation variable: `var'"
        local mother_var "`var'"
        local has_mother_occ = 1
        continue, break
    }
}

// Check for common fathers' occupation variables
foreach var in father_occ fatherocc father_occupation fatheroccupation dad_occ dadocc {
    capture confirm variable `var'
    if !_rc {
        di as txt "Found father occupation variable: `var'"
        local father_var "`var'"
        local has_father_occ = 1
        continue, break
    }
}

// Check for the parent type + own/partner occupation structure
capture confirm variable Parent_type_
if !_rc {
    di as txt "Found Parent_type_ variable - checking for own/partner occupations"
    
    local own_occ_var ""
    local partner_occ_var ""
    
    // Check for own occupation variables
    foreach var in own_occupation ownoccupation own_occ ownocc occupation {
        capture confirm variable `var'
        if !_rc {
            di as txt "Found own occupation variable: `var'"
            local own_occ_var "`var'"
            continue, break
        }
    }
    
    // Check for partner occupation variables
    foreach var in partner_occupation partneroccupation partner_occ partnerocc {
        capture confirm variable `var'
        if !_rc {
            di as txt "Found partner occupation variable: `var'"
            local partner_occ_var "`var'"
            continue, break
        }
    }
    
    // If we found both own and partner occupation variables, create standardized ones
    if "`own_occ_var'" != "" & "`partner_occ_var'" != "" {
        di as txt "Creating standardized mother/father variables based on Parent_type_..."
        
        // Create temporary mother/father occupation variables
        gen temp_mother_occ = ""
        gen temp_father_occ = ""
        
        // Fill based on parent type
        replace temp_mother_occ = `own_occ_var' if Parent_type_ == 1
        replace temp_mother_occ = `partner_occ_var' if Parent_type_ == 2
        
        replace temp_father_occ = `partner_occ_var' if Parent_type_ == 1
        replace temp_father_occ = `own_occ_var' if Parent_type_ == 2
        
        // Use these as our occupation variables
        local mother_var "temp_mother_occ"
        local father_var "temp_father_occ"
        
        local has_mother_occ = 1
        local has_father_occ = 1
    }
}

********************************************************************************
// 3. DIRECT ISCED CODE ASSIGNMENT
********************************************************************************
di as txt "----- Assigning ISCED codes directly -----"

// Process mother occupations if available
if `has_mother_occ' {
    di as txt "Processing mother occupations from variable: `mother_var'"
    
    // Assign ISCED codes based on standard categories
    replace mother_occ_isced6_final = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
         if `mother_var' == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Dienstleistungen und Detailhandel" ///
         if `mother_var' == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Wirtschaft, Verwaltung und Recht" ///
         if `mother_var' == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
         if `mother_var' == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
         if (`mother_var' == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
            `mother_var' == "Sozialwissenschaften, Journalismus und Geisteswissenschaften") & missing(mother_occ_isced6_final)
    
    replace mother_occ_isced6_final = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
         if `mother_var' == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" & missing(mother_occ_isced6_final)
    
    // Common special cases
    replace mother_occ_isced6_final = "Hausfrau/mann" if inlist(lower(`mother_var'), "hausfrau", "hausmann", "hausfrau/mann") & missing(mother_occ_isced6_final)
    
    // Count how many were directly mapped
    count if !missing(mother_occ_isced6_final) & !missing(`mother_var')
    local n_mapped = r(N)
    count if missing(mother_occ_isced6_final) & !missing(`mother_var')
    local n_unmapped = r(N)
    
    di as txt "Direct mapping for mother occupations: `n_mapped' mapped, `n_unmapped' unmapped"
}
else {
    di as txt "No mother occupation variable found."
}

// Process father occupations if available
if `has_father_occ' {
    di as txt "Processing father occupations from variable: `father_var'"
    
    // Assign ISCED codes based on standard categories
    replace father_occ_isced6_final = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
         if `father_var' == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Dienstleistungen und Detailhandel" ///
         if `father_var' == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Wirtschaft, Verwaltung und Recht" ///
         if `father_var' == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
         if `father_var' == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
         if (`father_var' == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
            `father_var' == "Sozialwissenschaften, Journalismus und Geisteswissenschaften") & missing(father_occ_isced6_final)
    
    replace father_occ_isced6_final = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
         if `father_var' == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" & missing(father_occ_isced6_final)
    
    // Common special cases
    replace father_occ_isced6_final = "Hausfrau/mann" if inlist(lower(`father_var'), "hausfrau", "hausmann", "hausfrau/mann") & missing(father_occ_isced6_final)
    
    // Count how many were directly mapped
    count if !missing(father_occ_isced6_final) & !missing(`father_var')
    local n_mapped = r(N)
    count if missing(father_occ_isced6_final) & !missing(`father_var')
    local n_unmapped = r(N)
    
    di as txt "Direct mapping for father occupations: `n_mapped' mapped, `n_unmapped' unmapped"
}
else {
    di as txt "No father occupation variable found."
}

********************************************************************************
// 4. CREATE NUMERIC ISCED FIELDS
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
// 5. EXPORT UNMAPPED OCCUPATIONS FOR REFERENCE
********************************************************************************
di as txt "----- Exporting unmapped occupations for reference -----"

// Setup for unmapped export
tempfile unmapped_combined

// Export unmapped mother occupations
if `has_mother_occ' {
    preserve
        keep if !missing(`mother_var') & missing(mother_occ_isced6_final)
        if _N > 0 {
            di as txt "Found `=_N' unmapped mother occupations, exporting."
            keep ResponseId `mother_var'
            gen occ_type = "mother"
            rename `mother_var' parent_occ
            
            save `unmapped_combined', replace
        }
        else {
            di as txt "No unmapped mother occupations found."
        }
    restore
}

// Export unmapped father occupations
if `has_father_occ' {
    preserve
        keep if !missing(`father_var') & missing(father_occ_isced6_final)
        if _N > 0 {
            di as txt "Found `=_N' unmapped father occupations, exporting."
            keep ResponseId `father_var'
            gen occ_type = "father"
            rename `father_var' parent_occ
            
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
        
        // Ensure processed_data/PS_Parents directory exists
        capture mkdir "${processed_data}/PS_Parents"
        
        // Export to Excel
        capture export excel ResponseId occ_type parent_occ using "${processed_data}/PS_Parents/unmapped_occupations.xlsx", ///
            firstrow(variables) replace
            
        if !_rc {
            di as txt "Exported unmapped occupations to ${processed_data}/PS_Parents/unmapped_occupations.xlsx"
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
// 6. SAVE FINAL DATASET
********************************************************************************
di as txt "----- Saving final dataset -----"

// Drop temporary variables if they exist
foreach var in temp_mother_occ temp_father_occ {
    capture drop `var'
}

// Final verification
count if !missing(mother_occ_isced6_final)
di as txt "Mother occupations with ISCED codes: `r(N)'"
count if !missing(father_occ_isced6_final)
di as txt "Father occupations with ISCED codes: `r(N)'"

// Compress and save final dataset
compress
save "${processed_data}/PS_Parents/9_ps_parents.dta", replace

// Final report
di as txt "Cleaned parent occupations dataset saved to: ${processed_data}/PS_Parents/9_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Clean Parent Occupations"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off