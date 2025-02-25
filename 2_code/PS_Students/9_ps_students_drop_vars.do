/*******************************************************************************
* 9_ps_students_drop_vars.do
* -----------------------------------------------------------------------------
* Matches structure from sample dataset provided - 25.02.2025
*******************************************************************************/

// SETUP ENVIRONMENT
// -----------------------------------------------------------------------------
clear all
version 18.0
set more off
cap log close
log using "${dodir_log}/students_drop_vars.log", replace text
timer clear
timer on 1

// LOAD DATA
// -----------------------------------------------------------------------------
use "${processed_data}/PS_Students/ps_stu_clean_parent_occs.dta", clear

// VARIABLE CLEANING: DROP UNNEEDED VARIABLES
// -----------------------------------------------------------------------------

// 1. Metadata and Qualtrics Variables
capture drop StartDate EndDate Status Progress Duration_* Finished RecordedDate
capture drop Recipient* ExternalReference* DistributionChannel UserLanguage 
capture drop _v* contactid* debug_contract* 

// 2. Survey Process Variables
capture drop duration* feedback* sure consent2 cons_* fut_survey_pof
capture drop t_* // Drop all timing variables

// 3. Text Variables and Free Responses
capture drop *friend_* *Text* *TEXT* *q_text* *concern* *suggest* *reason* 
capture drop *perc_adv* *perc_disadv* *contact_hc* *motFactor* *_merge*

// 4. Occupational Preference Variables
capture drop *app_pref_* *offer* *reject* *apply_occs* *ta_occs* *FaGe* *FaBe*
capture drop *MPA* *Apotheke* *GesundSoz* *Dent* *school_type* *track_*

// 5. Parental Input Variables
capture drop *mother_* *father_* *parent_* *child_* *birth* *field_educ*

// VARIABLE MANAGEMENT: RECODE
// -----------------------------------------------------------------------------

// Handle Consent Variables
gen byte consent_1st_time = (consent1 == 1) if !missing(consent1)
lab var consent_1st_time "Consent given at first contact"
drop if inlist(consent1, 2, .) // Drop non-consenting respondents

// VARIABLE ORDERING (Based on sample structure)
// -----------------------------------------------------------------------------

// Core Identifiers and Demographics
order ResponseId contract female sit age canton 

// Apprenticeship Information
order plan plan__~T // Free-text apprenticeship response and cleaned version

// Household Characteristics
order home_sit_stu // Home situation

// Survey Metadata (Keep at end)
//order consent1 consent_1st_time *_timestamp *_duration, last

// FINALIZE DATASET
// -----------------------------------------------------------------------------

// 1. Compress and Validate
compress
desc, short // Should show ~15-20 variables

// 2. Save Clean Dataset
save "${processed_data}/PS_Students/ps_stu_final.dta", replace

// WRAP UP
// -----------------------------------------------------------------------------
timer off 1
timer list
log close