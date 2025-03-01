********************************************************************************
* 9_ps_parents_drop_vars.do
*
* Purpose:
* - Final pass: drop extraneous variables, reorder key variables, produce
*   final cleaned PS Parents dataset.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/9_ps_parents_drop_vars.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD MERGED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_merge_chars.dta", clear
di as txt "Loaded ps_par_merge_chars.dta: `c(N)' obs"

********************************************************************************
* 2. DROP UNNEEDED VARIABLES
********************************************************************************

* Drop Qualtrics metadata
capture drop StartDate EndDate Status Progress Duration_* Finished RecordedDate
capture drop Recipient* ExternalReference* DistributionChannel UserLanguage
capture drop _v* contactid*

* Drop timing variables
capture drop t_*  // if not needed
capture drop sure consent2

* Drop large sets of free text or repeated fields not needed for final analysis
capture drop *Text* *TEXT* *concern* *suggest* *reason*

* Drop occupational preference expansions not needed
capture drop *offers* *reject_ta* *apply_occs* *ta_occs* *FaGe* *FaBe*
capture drop *MPA* *Apotheke* *GesundSoz* *Dent* *q_text* *school_type*

* etc. - tailor to your data

********************************************************************************
* 3. REORDER / CREATE FINAL VARIABLES
********************************************************************************

* Example: create a final consent variable
gen byte consent_1st_time = (consent1 == 1)
label var consent_1st_time "Consent given at first contact"
drop if inlist(consent1, 2, .)  // remove non-consent

* Reorder
order ResponseId contract female consent_1st_time

********************************************************************************
* 4. SAVE FINAL DATASET
********************************************************************************

compress
desc, short
save "${processed_data}/PS_Parents/ps_parents_final.dta", replace

timer off 1
timer list
log close
