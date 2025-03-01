********************************************************************************
* 5_ps_parents_clean_motivations.do
*
* Purpose:
* - Process and transform parental motivation factors (analogous to the 
*   students’ motivations processing).
* - It handles both numeric variables (motFactor variables) and string 
*   variables (motFactors_this and motFactors_other) by creating binary
*   indicator variables (fac_1 to fac_13) for each motivational factor.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 01.03.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING & LOGGING
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
log using "${dodir_log}/ps_parents_clean_motivations.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_par_clean_beliefs.dta -----"
quietly use "${processed_data}/PS_Parents/ps_par_clean_beliefs.dta", clear
di as txt "Loaded ps_par_clean_beliefs.dta: `c(N)' obs, `c(k)' vars"
if _N == 0 {
    di as error "ERROR: No observations in ps_par_clean_beliefs.dta."
    error 601
}

********************************************************************************
* 2. MOTIVATIONAL FACTORS PROCESSING (NUMERIC VARIABLES)
********************************************************************************
* This section maps the labels of numeric motivational factor variables to 
* factor numbers for each role (child, mother, father). It assumes that the
* numeric variables (motFactor1, motFactor2, …, motFactor12) exist and that 
* their variable labels contain the corresponding factor text.
********************************************************************************

* Create empty factor indicator variables for each role
foreach role in child mother father {
    forval i = 1/13 {
        gen `role'_fac_`i' = 0
        label variable `role'_fac_`i' "`role' motivation factor `i'"
    }
}

* Process each motivational factor question (assumed indices 1 to 12)
forval j = 1/12 {
    local current_label : var label motFactor`j'
    local factor_num = 0
    
    if "`current_label'" == "Der zukünftige <strong>Lohn</strong>" {
        local factor_num = 1
    }
    else if "`current_label'" == "Die zukünftige berufliche <strong>Flexibilität</strong>" {
        local factor_num = 2
    }
    else if "`current_label'" == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>" {
        local factor_num = 3
    }
    else if "`current_label'" == "Die <strong>mathematischen</strong> Anforderungen" {
        local factor_num = 4
    }
    else if "`current_label'" == "Die <strong>sprachlichen</strong> Anforderungen" {
        local factor_num = 5
    }
    else if "`current_label'" == "Die <strong>Empfehlungen der Eltern</strong>" {
        local factor_num = 6
    }
    else if "`current_label'" == "Die <strong>Geschlechterzusammensetzung</strong>" {
        local factor_num = 7
    }
    else if "`current_label'" == "Das Ausmass an <strong>sozialem Kontakt</strong>" {
        local factor_num = 8
    }
    else if "`current_label'" == "Menschen zu <strong>helfen</strong>" {
        local factor_num = 9
    }
    else if "`current_label'" == "Der <strong>Arbeitsort</strong>" {
        local factor_num = 10
    }
    else if "`current_label'" == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen" {
        local factor_num = 11
    }
    else if "`current_label'" == "Die Aussicht auf <strong>Beförderungen</strong>" {
        local factor_num = 12
    }
    else if "`current_label'" == "Ihre persönlichen <strong>Interessen</strong>" {
        local factor_num = 13
    }
    
    if `factor_num' != 0 {
        foreach role in child mother father {
            quietly replace `role'_fac_`factor_num' = 1 if motFactor_`role'_`j' == 1
        }
    }
    else {
        di as error "WARNING: Unmapped label found: `current_label'"
    }
}

********************************************************************************
* 3. PROCESS MOTIVATIONAL FACTORS FROM STRING VARIABLES
********************************************************************************
* In addition to the numeric variables, parental motivations may also be 
* captured in string variables (motFactors_this and motFactors_other) which list 
* selected factors in a comma-separated format.
********************************************************************************

* Create empty factor indicator variables for the string-based responses
foreach role in this other {
    forval i = 1/13 {
        gen `role'_fac_`i' = 0
        label variable `role'_fac_`i' "`role': factor `i'"
    }
}

* Define a factor mapping (adjust as needed) in pairs: factor text followed by its number.
local factor_map "Der zukünftige <strong>Lohn</strong> 1 Die zukünftige berufliche <strong>Flexibilität</strong> 2 Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong> 3 Die <strong>mathematischen</strong> Anforderungen 4 Die <strong>sprachlichen</strong> Anforderungen 5 Die <strong>Empfehlungen der Eltern</strong> 6 Die <strong>Geschlechterzusammensetzung</strong> 7 Das Ausmass an <strong>sozialem Kontakt</strong> 8 Menschen zu <strong>helfen</strong> 9 Der <strong>Arbeitsort</strong> 10 Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen 11 Die Aussicht auf <strong>Beförderungen</strong> 12 Ihre persönlichen <strong>Interessen</strong> 13"

quietly {
    foreach role in this other {
        local varname = "motFactors_`role'"
        capture confirm variable `varname'
        if !_rc {
            forval i = 1/13 {
                local txt: word ((`i'-1)*2+1) of "`factor_map'"
                * Check if the string variable contains the factor text.
                replace `role'_fac_`i' = 1 if strpos(`varname', "`txt'") > 0
            }
        }
        else {
            di as txt "Variable `varname' not found, skipping factor parsing for `role'"
        }
    }
}

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************
compress
save "${processed_data}/PS_Parents/ps_par_clean_motivations.dta", replace

timer off 1
timer list
log close
