********************************************************************************
* 6_ps_parents_clean_concerns.do
* --------------------------------------------------------------------------------------------
* Data needed: ps_par_clean_motivations.dta
* Data output: 6_ps_parents_clean_concerns.do
* Purpose:
* - Process and transform parental concerns and make them readable
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 03.03.2025
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
log using "${dodir_log}/6_ps_parents_cleaning_concerns.log", replace text

timer clear
timer on 1
********************************************************************************
* 1. DATA
********************************************************************************
********************************************************************************
* 2.CLEAN
********************************************************************************
forval i = 1/6 {
    gen concern_`i' = .
}

foreach q in "work_env" "work_life_balance" "skill_fit" "career_opportunities" "personality_fit" "unknown_career" {
    forval j = 1/6 {
        replace concern_1 = 1 if concern`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
        replace concern_2 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
        replace concern_3 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
        replace concern_4 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
        replace concern_5 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
        replace concern_6 = 1 if concern`j' == "Ich weiß nicht viel über diesen Beruf"
    }
}
forval i = 1/6 {
    replace concern_`i' = 0 if missing(concern_`i')
}

local concern_1 "Work Environment Concerns"
local concern_2 "Work-Life Balance Concerns"
local concern_3 "Skill Fit Concerns"
local concern_4 "Career Opportunity Concerns"
local concern_5 "Personality Fit Concerns"
local concern_6 "Lack of Knowledge About Career"

forval i = 1/6 {
    label var concern_`i' "`concern_`i''"
}

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************
compress
save "${processed_data}/PS_Parents/ps_par_clean_concerns.dta", replace

timer off 1
timer list
log close
