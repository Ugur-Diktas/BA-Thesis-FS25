********************************************************************************
* 5_ps_parents_clean_motivations.do
*
* Purpose:
* - Process and transform parental motivation factors (similar to how students'
*   motivations are handled in ps_students_clean_motivations.do).
* - Typically uses variables like "motFactors_this" and "motFactors_other".
* - Map each selected factor to numeric indicators (fac_1, fac_2, ...).
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
log using "${dodir_log}/5_ps_parents_clean_motivations.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_clean_beliefs.dta", clear
di as txt "Loaded ps_par_clean_beliefs.dta: `c(N)' obs, `c(k)' vars"
if _N == 0 {
    di as error "ERROR: No observations in ps_par_clean_beliefs.dta."
    error 601
}

********************************************************************************
* 2. DEFINE MOTIVATION FACTOR MAPPING
********************************************************************************

* Example factor map (German text -> factor #)
* Adjust these to match your parent's "motFactors_this" or "motFactors_other" text
local factor_map ///
"Der zukünftige <strong>Lohn</strong>" 1 ///
"Die zukünftige berufliche <strong>Flexibilität</strong>" 2 ///
"Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>" 3 ///
"Die <strong>mathematischen</strong> Anforderungen" 4 ///
"Die <strong>sprachlichen</strong> Anforderungen" 5 ///
"Die <strong>Empfehlungen der Eltern</strong>" 6 ///
"Die <strong>Geschlechterzusammensetzung</strong>" 7 ///
"Das Ausmass an <strong>sozialem Kontakt</strong>" 8 ///
"Menschen zu <strong>helfen</strong>" 9 ///
"Der <strong>Arbeitsort</strong>" 10 ///
"Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen" 11 ///
"Die Aussicht auf <strong>Beförderungen</strong>" 12 ///
"Ihre persönlichen <strong>Interessen</strong>" 13

********************************************************************************
* 3. CREATE MOTIVATION FACTOR VARIABLES
********************************************************************************

* Suppose we have two string variables: motFactors_this, motFactors_other
* We'll create this_fac_1..13, other_fac_1..13 as 0/1 indicators
foreach role in this other {
    forval i = 1/13 {
        gen `role'_fac_`i' = 0
        label var `role'_fac_`i' "`role': factor `i'"
    }
}

********************************************************************************
* 4. POPULATE FACTORS
********************************************************************************

quietly {
    * We'll assume each motFactors_* is a string with comma-separated factor text
    * e.g. "Der zukünftige <strong>Lohn</strong>,Die <strong>Geschlechterzusammensetzung</strong>"
    foreach role in this other {
        local varname = "motFactors_`role'"
        capture confirm variable `varname'
        if !_rc {
            forval i = 1/13 {
                * The factor text from the map
                local txt: word ((`i'-1)*2+1) of "`factor_map'"
                local code: word ((`i'-1)*2+2) of "`factor_map'"
                * Check if the parent's string includes `txt'
                replace `role'_fac_`i' = 1 if strpos(`varname', "`txt'") > 0
            }
        }
        else {
            di as txt "No variable `varname' found, skipping factor parsing for `role'"
        }
    }
}

********************************************************************************
* 5. FINAL HOUSEKEEPING & SAVE
********************************************************************************

compress
save "${processed_data}/PS_Parents/ps_par_clean_motivations.dta", replace

timer off 1
timer list
log close
