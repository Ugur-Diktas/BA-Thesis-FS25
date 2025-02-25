/**********************************************************************************************
 * clean_apprenticeships.do
 * --------------------------------------------------------------------------------------------
 * Purpose:
 *   - Takes as input data with text entries of apprenticeship names (one variable named 
 *     "Apprenticeship" with no other variables).
 *   - Checks which apprenticeship names have already been cleaned.
 *   - Produces a list of apprenticeship names that still need to be cleaned.
 *   - After you manually assign apprenticeship codes to the uncleaned text entries (by 
 *     updating Sheet 2 in "clean apprenticeships.xlsx"), merges all cleaned apprenticeships 
 *     with apprenticeship characteristics data.
 *   - Outputs an updated dataset "clean apprenticeships.dta" serving as a crosswalk from
 *     uncleaned apprenticeship names to LABB codes, official apprenticeship names, and 
 *     corresponding apprenticeship characteristics.
 *
 *   Example Output (columns):
 *     Text entry              	| labb_code_1 | labb_code_2 | app_official_1                | app_official_2                | app_math_score_1 | app_math_score_2
 *     --------------------------------------------------------------------------------------------
 *     I want to do FaGe or FaBe| 462800      | 463200      | Fachmann/-frau Gesundheit EFZ | Fachmann/-frau Betreuung EFZ  | 23.8             | 27.1667
 *     KV                     	| 384350      |             | Kaufmann/-frau EFZ E          |                               | 44.8             |
 *
 * Data Requirements:
 *   - One variable named "Apprenticeship" that contains potentially uncleaned apprenticeship
 *     names.
 *
 * Preparation:
 *   - Set global appchardir to your path for apprenticeship characteristics data, e.g.:
 *         global appchardir "T:\econ\brenoe\11_yousty\5_ApprenticeshipCharacteristics"
 *
 * Steps to Follow:
 *   1. Run this do-file; Sheet 1 in "clean apprenticeships.xlsx" will be updated with your 
 *      new uncleaned apprenticeships.
 *   2. Copy all apprenticeships with cleaned == 0 to the bottom of Sheet 2, and manually add 
 *      the corresponding LABB codes.
 *   3. Run this do-file again; "clean apprenticeships.dta" will be updated with your apprenticeships.
 *   4. Merge your data to "clean apprenticeships.dta" to obtain LABB codes and other apprenticeship
 *      characteristics.
 *
 *   You can use this do-file if you have more than one variable with potentially uncleaned 
 *   apprenticeship names. See example.do for instructions.
 *
 * Author : Daphne Rutnam (adapted for current project by Ugur Diktas, Jelke Clarysse)
 * Last Updated: 25.02.2025
 **********************************************************************************************/
 
//----------------------------------------------------------------------------
// 1. PREPARE THE CHARACTERISTICS DATASET
//----------------------------------------------------------------------------
preserve
    use "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics", clear
 
    replace labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
    replace labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"
    drop if missing(labb_code)
    drop if labb_code == 384450
 
    replace labb_code = 1000002 if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    replace occname_labb = "Gebäudetechnikplaner/in EFZ" if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    egen tag = tag(labb_code)
    bys labb_code: egen nofspecs = total(labb_first)
    bys labb_code: egen total_grad_allspecs = total(total_grad) if nofspecs > 1
    replace total_grad_allspecs = total_grad if nofspecs == 1
    drop total_grad
    rename total_grad_allspecs total_grad
    bys labb_code: egen flag_total_grad_miss = total(missing(total_grad))
    bys labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
    replace total_grad = 1 if flag_total_grad_miss == 1
    collapse (mean) skills_ave_math skills_ave_ownlang ///
         skills_ave_forlang skills_ave_science ///
         female_grad total_grad expearn ///
         (first) occname_skill occname_labb flag_total_grad_miss ///
         isced4_code isced4_name isced3_code isced3_name isced2_code ///
         isced2_name job_ch_isco_19 [aw=total_grad], by(labb_code)
    replace total_grad = . if flag_total_grad_miss == 1
    drop flag_total_grad_miss
 
    su skills_ave_ownlang [w=total_grad], d
    scalar median_lang = r(p50)
    di "Median language requirement score: " median_lang
 
    replace occname_labb = occname_skill if missing(occname_labb)
    drop occname_skill
 
    drop if labb_code == 381400
    local nplusone = _N + 1
    set obs `nplusone'
    replace occname_labb = "Entwickler/in Digitales Business EFZ" in `nplusone'
    replace labb_code = 1000001 in `nplusone'
    su skills_ave_math if occname_labb == "Informatiker/in EFZ"
    replace skills_ave_math = r(mean) in `nplusone'
    su female_grad if occname_labb == "Informatiker/in EFZ"
    replace female_grad = r(mean) in `nplusone'
 
    set obs `=_N+3'
    forvalues i = 1/3 {
        replace labb_code = -`i' in `=_N-3+`i''
    }
    replace occname_labb = "None" in `=_N-2'
    replace occname_labb = "Gymnasium" in `=_N-1'
    replace occname_labb = "Has contract" in `=_N'
    
    set obs `=_N+4'
    forvalues i = 1/4 {
        replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
        replace labb_code = -3 - `i' in `=_N-4+`i''
    }
    set obs `=_N+1'
    replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
    replace labb_code = -8 in `=_N'
    
    tempfile appchardata
    save `appchardata'
restore
 
//----------------------------------------------------------------------------
// 2. FILL IN UN-CLEANED APPRENTICESHIP NAMES
//----------------------------------------------------------------------------
use "${clean_apprenticeships}/clean apprenticeships.dta", clear
duplicates report Apprenticeship
duplicates drop Apprenticeship, force
save "${clean_apprenticeships}/clean apprenticeships.dta", replace

// Merge with self to identify cleaned entries
merge 1:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships.dta", ///
    force generate(_merge_temp)  // Unique name for merge variable

gen cleaned = (_merge_temp == 3 | _merge_temp == 2)
drop _merge_temp  // Explicitly drop the temporary merge variable

sort cleaned Apprenticeship
keep Apprenticeship cleaned
order Apprenticeship cleaned
keep if cleaned == 0
tempfile uncleaned
save `uncleaned'
 
//----------------------------------------------------------------------------
// 3. UPDATE THE EXTERNAL EXCEL FILE WITH UN-CLEANED NAMES
//----------------------------------------------------------------------------
import excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", sheet("Sheet1") firstrow clear
destring cleaned, replace force  

// Merge with uncleaned data using a unique merge variable
merge 1:1 Apprenticeship using `uncleaned', update replace generate(_merge_update)

replace cleaned = 1 if _merge_update == 3
drop _merge_update  // Drop the temporary merge variable

// Merge with characteristics data (use nogen to suppress merge variable)
merge m:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships.dta", ///
    keep(master match) keepusing(labb_code_1 app_official_1) force nogen

sort cleaned Apprenticeship
export excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
    sheet("Sheet1") sheetmodify cell(A1) firstrow(variables) keepcellfmt
 
//----------------------------------------------------------------------------
// 4. IMPORT THE CLEANED EXCEL FILE AND MERGE WITH CHARACTERISTICS DATA
//----------------------------------------------------------------------------
import excel "${clean_apprenticeships}/clean apprenticeships.xlsx", sheet("Sheet2") firstrow clear
keep Apprenticeship labb_code_*
drop if missing(Apprenticeship)
forvalues i = 1/4 {
    rename labb_code_`i' labb_code
    merge m:1 labb_code using `appchardata', ///
        keep(master match) ///
        keepusing(occname_labb skills_ave_math skills_ave_ownlang ///
                  skills_ave_forlang skills_ave_science female_grad expearn)
    list Apprenticeship labb_code if _merge != 3 & !missing(labb_code) & labb_code > 0
    count if _merge != 3 & !missing(labb_code) & labb_code > 0
    if r(N) > 0 {
        di as txt "Please check the entries above. There may be a typo."
    }
    assert _merge == 3 if !missing(labb_code) & labb_code > 0
    drop _merge
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
// 5. CATEGORIZE MATH REQUIREMENT SCORES
//----------------------------------------------------------------------------
forvalues i = 1/4 {
    recode app_math_score_`i' (0/37.49999 = 1 "low") ///
                              (37.5/58.49999 = 2 "medium") ///
                              (58.5/100 = 3 "high"), gen(app_math_`i')
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
 
//----------------------------------------------------------------------------
// 6. EXPORT THE CROSSWALK AND SAVE THE DATASET
//----------------------------------------------------------------------------
order Apprenticeship app_official_* labb_code_* app_math_score_* ///
      app_math_* app_lang_score_* app_foreign_score_* ///
      app_science_score_* app_femshare_* app_salary30_*

// Ensure _merge is dropped before saving
capture drop _merge  // Use capture to avoid errors if _merge doesn't exist

export excel using "${clean_apprenticeships}/clean apprenticeships.xlsx", ///
    sheet("Sheet3") sheetmodify cell(A1) firstrow(variables) keepcellfmt

save "${clean_apprenticeships}/clean apprenticeships.dta", replace