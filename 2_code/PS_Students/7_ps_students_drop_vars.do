********************************************************************************
// 7_ps_students_drop_vars.do
// Purpose : Drops unnecessary variables from the PS Students dataset,
//           renames and orders remaining variables, and saves the final clean file.
// 
// Author  : Your Name (BA Thesis FS25, dd.mm.yyyy)
********************************************************************************

clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_drop_vars.log", replace text

timer clear
timer on 1

set seed 123

*---------------------------------------------------------------
* Load the last cleaned PS Students dataset
*---------------------------------------------------------------
use "${processed_data}/PS_Students/ps_stu_clean_parent_occs.dta", clear

*****************************************
/*      (A) Drop variables             */
*****************************************

capture drop *dup*

* Drop variables used for cleaning parent occupations  
capture drop mother_occ_isced6*  
capture drop father_occ_isced6*
capture drop mother_occ
capture drop father_occ

* Drop variables that are only in pilot or not needed from Qualtrics
capture drop app_pref_rank3*
capture drop _v*
capture drop contactid*
capture drop treatment_parent*
capture drop apply_occ1
capture drop externalreference*
capture drop debug_contract_
capture drop fage
capture drop fabe
capture drop mpa
capture drop apotheke
capture drop gesundsoz
capture drop dent
capture drop q1*
capture drop q7*
capture drop kv
capture drop detail
capture drop info
capture drop logi
capture drop hc
capture drop neutral
capture drop high_math

* Drop duration variables
capture drop duration*

* Drop variables used in panel merging (if any)
capture drop p_fit_m_*
capture drop p_fit_f_*
capture drop p_best_fit*
capture drop p1_fit*
capture drop p2_fit*
capture drop prefchild*
capture drop mother_pref*
capture drop father_pref*
capture drop child_pref*

* Drop variables used for cleaning schools (if applicable)
capture drop school_type1
capture drop school_type2
capture drop school_type3
capture drop school_type4
capture drop school_type5
capture drop school_type6
capture drop school_type7

* Drop RCT school questions
capture drop rct_lu*
capture drop rct_zh*
capture drop *_ort
capture drop *_bezirk
capture drop *_stadt
capture drop town

* Drop app preference favorite variables
capture drop app_pref_fav*

* Drop friend text variables
capture drop friend_nom
capture drop friend_gen
capture drop friend_dat
capture drop friend_akk

* Drop TA and occ_points variables
capture drop ta
capture drop occ_points*

* Drop variables used for cleaning school, math and language
capture drop track_1
capture drop track_2
capture drop school_track_name
capture drop flag_missing_track_error
capture drop track_error
capture drop old_track_standardized
capture drop school_type
capture drop school_track
capture drop math_level
capture drop math_track
capture drop high_math_stratif
capture drop lang_level
capture drop canton_el_1
capture drop canton_el_2

* Drop consent variables after processing consent
gen consent_1st_time = consent1 == 1
lab var consent_1st_time "Consent 1st time"
drop if consent2 == 2 | missing(consent1)
capture drop consent1
capture drop sure
capture drop consent2
capture drop consent_merge
capture drop cons_yousty_merge
capture drop cons_survey_merge
capture drop fut_survey_pof

* Drop feedback variables
capture drop feedback*

* Drop question text variables
capture drop sie_er
capture drop ihren_seinen
capture drop ihrem_seinem
capture drop ihre_seine
capture drop ihr_sein
capture drop ihr_ihm
capture drop sie_ihn
capture drop ihrer_seiner

* Drop variables used for conditions in Qualtrics
capture drop parent_3_choices
capture drop child_3_choices
capture drop child_m_other*
capture drop parent_m_other*
capture drop child_f_other*
capture drop parent_f_other*

*****************************************
/*      (B) Rename variables           */
*****************************************

capture rename math_level_track math_track
capture rename lang_level_track lang_track

*****************************************
/*      (C) Order variables            */
*****************************************

* Instead of listing variables directly (which causes errors if a variable is missing),
* we build a local macro "orderVars" that includes only variables that exist.

local orderVars ""

* List individual variables we want (check each one):
foreach var in ResponseId contract female sit age ta_done contract_occ app_pref_rank1 app_pref_rank2 mother_rank1 mother_rank2 father_rank1 father_rank2 parents_rank1 parents_rank2 {
    capture confirm variable `var'
    if _rc == 0 {
        local orderVars "`orderVars' `var'"
    }
}

* For wildcards or groups, use ds to list matching variables:
ds boyshc_dataset
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}

ds track
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}

ds math_track
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}

ds lang_track
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}

ds child_fac*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_fac*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_fac*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds belief_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds like_task*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds colleague_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds belief_demand*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds marriage_prob*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds future_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_belief_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_like_task*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_colleague_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_belief_demand*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_marriage_prob*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds mother_future_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_belief_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_like_task*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_colleague_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_belief_demand*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_marriage_prob*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}
ds father_future_fit*
if "`r(varlist)'" != "" {
    local orderVars "`orderVars' `r(varlist)'"
}

* Finally, order the variables using the constructed macro
order `orderVars'

*****************************************
/*      (D) Save final dataset         */
*****************************************
compress
save "${processed_data}/PS_Students/ps_stu_final.dta", replace

timer off 1
timer list

log close
