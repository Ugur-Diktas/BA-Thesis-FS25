/**********************************************************************************************
 * clean_apprenticeships.do
 * --------------------------------------------------------------------------------------------
 * Purpose:
 *   - Processes text entries of apprenticeship names and creates a standardized mapping to LABB codes.
 *   - Handles both previously processed apprenticeships and new unmatched entries.
 *   - Updates the Excel file for manual review of new entries.
 *   - Produces a comprehensive crosswalk dataset between raw text and standardized codes.
 *
 * Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
 * Last edit: 10.03.2025
 * Version: Stata 18
 **********************************************************************************************/
 
//----------------------------------------------------------------------------
// 0. SETUP - Check if input variable exists
//----------------------------------------------------------------------------
capture confirm variable Apprenticeship
if _rc {
    di as error "ERROR: This do-file requires a variable named 'Apprenticeship' to be present in the dataset."
    exit 111
}

//----------------------------------------------------------------------------
// 1. PREPARE CHARACTERISTICS DATA
//----------------------------------------------------------------------------
preserve
    // Load apprenticeship characteristics data
    use "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics", clear
 
    // Special case handling
    capture confirm variable labb_code
    if !_rc {
        // These operations only happen if labb_code exists
        replace labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
        replace labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"
        drop if missing(labb_code)
        drop if labb_code == 384450
     
        // Standardize Gebäudetechnikplaner entries
        replace labb_code = 1000002 if strpos(occname_labb, "Gebäudetechnikplaner/in ")
        replace occname_labb = "Gebäudetechnikplaner/in EFZ" if strpos(occname_labb, "Gebäudetechnikplaner/in ")
        
        // Process specializations
        egen tag = tag(labb_code)
        bys labb_code: egen nofspecs = total(labb_first)
        bys labb_code: egen total_grad_allspecs = total(total_grad) if nofspecs > 1
        replace total_grad_allspecs = total_grad if nofspecs == 1
        drop total_grad
        rename total_grad_allspecs total_grad
        
        // Handle missing totals
        bys labb_code: egen flag_total_grad_miss = total(missing(total_grad))
        bys labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
        replace total_grad = 1 if flag_total_grad_miss == 1
        
        // Collapse to get one entry per LABB code
        collapse (mean) skills_ave_math skills_ave_ownlang ///
             skills_ave_forlang skills_ave_science skills_ave_all ///
             female_grad total_grad expearn immigrant_grad ///
             (first) occname_skill occname_labb flag_total_grad_miss ///
             isced4_code isced4_name isced3_code isced3_name isced2_code ///
             isced2_name job_ch_isco_19 [w=total_grad], by(labb_code)
             
        replace total_grad = . if flag_total_grad_miss == 1
        drop flag_total_grad_miss
     
        // Use skill name when LABB name is missing
        replace occname_labb = occname_skill if missing(occname_labb)
        drop occname_skill
     
        // Handle special cases for digital business and other newer professions
        drop if labb_code == 381400
        local nplusone = _N + 1
        set obs `nplusone'
        replace occname_labb = "Entwickler/in Digitales Business EFZ" in `nplusone'
        replace labb_code = 1000001 in `nplusone'
        
        // Copy metrics from Informatiker for new entries
        su skills_ave_math if occname_labb == "Informatiker/in EFZ"
        replace skills_ave_math = r(mean) in `nplusone'
        su female_grad if occname_labb == "Informatiker/in EFZ"
        replace female_grad = r(mean) in `nplusone'
     
        // Add special code entries for non-apprenticeship options
        set obs `=_N+3'
        forvalues i = 1/3 {
            replace labb_code = -`i' in `=_N-3+`i''
        }
        replace occname_labb = "None" in `=_N-2'
        replace occname_labb = "Gymnasium" in `=_N-1'
        replace occname_labb = "Has contract" in `=_N'
        
        // Add unknown/unclear entries codes
        set obs `=_N+4'
        forvalues i = 1/4 {
            replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
            replace labb_code = -3 - `i' in `=_N-4+`i''
        }
        set obs `=_N+1'
        replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
        replace labb_code = -8 in `=_N'
        
        // Standard name handling for common variations
        replace occname_labb = "Kaufmann/-frau EFZ" if occname_labb == "Kaufmann/-frau EFZ E"
        replace occname_labb = "Fachmann/-frau Apotheke EFZ" if occname_labb == "Pharma-Assistent/in EFZ"
    }
    else {
        di as error "WARNING: labb_code variable not found in characteristics data."
        di as txt "Creating minimal characteristics dataset."
        
        // Create minimal dataset if original was missing expected structure
        clear
        set obs 10
        gen labb_code = _n
        gen occname_labb = "Unknown"
        replace occname_labb = "None" if labb_code == 1
        replace occname_labb = "Gymnasium" if labb_code == 2
        replace labb_code = -1 if labb_code == 1
        replace labb_code = -2 if labb_code == 2
    }
    
    tempfile appchardata
    save `appchardata'
restore
 
//----------------------------------------------------------------------------
// 2. PROCESS THE CURRENT APPRENTICESHIPS
//----------------------------------------------------------------------------
// Ensure we have the clean_apprenticeships.dta, creating it if missing
capture confirm file "${clean_apprenticeships}/clean apprenticeships.dta"
if _rc {
    // If file doesn't exist, create basic structure
    preserve
        clear
        set obs 1
        gen Apprenticeship = ""
        gen labb_code_1 = .
        gen app_official_1 = ""
        save "${clean_apprenticeships}/clean apprenticeships.dta", replace
    restore
}

// Load existing clean apprenticeships dataset
preserve
    use "${clean_apprenticeships}/clean apprenticeships.dta", clear
    
    // Remove duplicates from the reference dataset
    duplicates report Apprenticeship
    duplicates drop Apprenticeship, force
    save "${clean_apprenticeships}/clean apprenticeships.dta", replace
restore

// Identify entries that haven't been cleaned yet
tempfile current_data
save `current_data'

// Merge with already cleaned data to identify what's new
merge m:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships.dta", ///
    force generate(_merge_status)

// Flag previously unseen entries
gen cleaned = (_merge_status == 3 | _merge_status == 2)
drop _merge_status

// Keep only new (uncleaned) entries for export
preserve
    keep if cleaned == 0 & !missing(Apprenticeship)
    keep Apprenticeship cleaned
    
    // If we have new uncleaned entries, export them
    count 
    if r(N) > 0 {
        tempfile uncleaned
        save `uncleaned'
        
        // Update the Excel workbook with new entries
        import excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
            sheet("Uncleaned Entries") firstrow clear allstring
            
        // Convert cleaned status for comparison
        destring cleaned, replace force
        
        // Append new uncleaned entries
        append using `uncleaned'
        
        // Ensure new entries are marked as uncleaned
        replace cleaned = 0 if missing(cleaned)
        
        // Sort and export to Excel
        sort cleaned Apprenticeship
        export excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
            sheet("Uncleaned Entries") sheetmodify cell(A1) firstrow(variables) keepcellfmt
            
        di as txt "Exported " r(N) " new entries to 'Uncleaned Entries' for manual review."
    }
    else {
        di as txt "No new apprenticeships to clean."
    }
restore

// Load manually cleaned data from Manual Mapping
import excel "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
    sheet("Manual Mapping") firstrow clear

// Process the LABB codes for each apprenticeship entry
keep Apprenticeship labb_code_*
drop if missing(Apprenticeship)

// Merge with characteristics data for each potential LABB code
forvalues i = 1/4 {
    rename labb_code_`i' labb_code
    capture merge m:1 labb_code using `appchardata', ///
        keep(master match) ///
        keepusing(occname_labb skills_ave_math skills_ave_ownlang ///
                  skills_ave_forlang skills_ave_science female_grad expearn)
                  
    // Warn about potential code issues
    if _rc == 0 {
        list Apprenticeship labb_code if _merge != 3 & !missing(labb_code) & labb_code > 0
        count if _merge != 3 & !missing(labb_code) & labb_code > 0
        if r(N) > 0 {
            di as txt "Please check the entries above. There may be a typo in the LABB code."
        }
    }
    
    // Clean up merge variable
    capture drop _merge
    
    // Rename variables with index
    rename skills_ave_math app_math_score_`i'
    rename skills_ave_ownlang app_lang_score_`i'
    rename skills_ave_forlang app_foreign_score_`i'
    rename skills_ave_science app_science_score_`i'
    rename female_grad app_femshare_`i'
    rename occname_labb app_official_`i'
    rename labb_code labb_code_`i'
    rename expearn app_salary30_`i'
}
 
//----------------------------------------------------------------------------
// 3. CATEGORIZE MATH REQUIREMENTS
//----------------------------------------------------------------------------
forvalues i = 1/4 {
    capture confirm variable app_math_score_`i'
    if !_rc {
        recode app_math_score_`i' (0/37.49999 = 1 "low") ///
                                  (37.5/58.49999 = 2 "medium") ///
                                  (58.5/100 = 3 "high"), gen(app_math_`i')
        
        // Fix specific occupations with known math requirements
        replace app_math_`i' = 1 if labb_code_`i' == 500400
        replace app_math_`i' = 3 if labb_code_`i' == 287210
        replace app_math_`i' = 3 if labb_code_`i' == 294560
        replace app_math_`i' = 2 if labb_code_`i' == 373800
        replace app_math_`i' = 2 if labb_code_`i' == 330800
        replace app_math_`i' = 1 if labb_code_`i' == 461700
        replace app_math_`i' = 1 if labb_code_`i' == 442600
        replace app_math_`i' = 2 if labb_code_`i' == 173100
        replace app_math_`i' = 3 if labb_code_`i' == 482600
        replace app_math_`i' = 2 if labb_code_`i' == 482100
        replace app_math_`i' = 1 if labb_code_`i' == 430400
        replace app_math_`i' = 2 if labb_code_`i' == 331200
        replace app_math_`i' = 2 if labb_code_`i' == 321600
        replace app_math_`i' = 3 if labb_code_`i' == 350510
        replace app_math_`i' = 2 if labb_code_`i' == 467700
        replace app_math_`i' = 2 if labb_code_`i' == 342600
        replace app_math_`i' = 2 if labb_code_`i' == 204100
        replace app_math_`i' = 2 if labb_code_`i' == 166600
    }
}
 
//----------------------------------------------------------------------------
// 4. SAVE THE FINAL CROSSWALK DATASET
//----------------------------------------------------------------------------
// Order variables logically
order Apprenticeship app_official_* labb_code_* app_math_score_* ///
      app_math_* app_lang_score_* app_foreign_score_* ///
      app_science_score_* app_femshare_* app_salary30_*

// Ensure _merge is dropped before saving
capture drop _merge

// Export to Excel for reference
export excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
    sheet("Complete Crosswalk") sheetmodify cell(A1) firstrow(variables) keepcellfmt

// Save as Stata dataset for future use
save "${clean_apprenticeships}/clean apprenticeships.dta", replace

di as txt "✓ Apprenticeship cleaning process completed successfully."
di as txt "  - The Excel file has been updated with any new entries."
di as txt "  - The crosswalk dataset has been saved."