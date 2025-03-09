********************************************************************************
* 1_ps_parents_anonymize.do
* ------------------------------------------------------------------------------
* Data needed: raw_data files
* Data output: ps_par_all_anon.dta
* Purpose:
*   - Import **all** PS Parents .sav files (finished & unfinished) using a 
*     wildcard approach (PoF_PS_Parents*.sav).
*   - Remove test/preliminary responses (by email, test names, preview status,
*     and official StartDate).
*   - Save sensitive data (IP, location, parent email and names) to a separate file.
*   - Save an anonymised version of the data (with sensitive variables dropped).
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
* 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

ls "${processed_data}/PS_Parents"


* Conditionally enable trace if debugging is requested
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

* Start logging
cap log close
log using "${dodir_log}/1_ps_parents_anonymize.log", replace

********************************************************************************
* 1. LOAD THE DATA
*    a. Import and combine all .sav files matching "PoF_PS_Parents*.sav"
********************************************************************************

local initial_dir "`c(pwd)'"   // preserve current directory
cd "${raw_data}"

* Identify all matching .sav files
local parfiles : dir . files "PoF_PS_Parents*.sav"

* If no files found, throw an error
if `:word count `parfiles'' == 0 {
    di as error "ERROR: No PS Parents .sav file found."
    cd "`initial_dir'"
    error 601
}

* Temporary file to hold combined data
tempfile combined
save `combined', emptyok

local Nfiles = `:word count `parfiles''

* Loop through all .sav files and append them
forval i = 1/`Nfiles' {
    local thisfile : word `i' of `parfiles'
    di as txt "Importing file #`i': `thisfile'"
    
    import spss using "`thisfile'", clear
    
    if `i' == 1 {
        save `combined', replace
    }
    else {
        tempfile nextpart
        save `nextpart', replace
        
        use `combined', clear
        append using `nextpart'
        
        save `combined', replace
    }
}

use `combined', clear   // final combined dataset in memory
cd "`initial_dir'"      // revert to original directory

********************************************************************************
* 2. DROP TEST RESPONSES
*    - Remove test/preliminary responses based on:
*         a) Parent email addresses (and domains)
*         b) Test names in RecipientFirstName / RecipientLastName (if applicable)
*         c) Qualtrics preview responses (Status == 1)
*         d) Responses before the official StartDate
********************************************************************************

* Drop test emails and any responses containing "uzh.ch" based on RecipientEmail
drop if inlist(RecipientEmail, ///
    "daphne.rutnam@econ.uzh.ch", ///
    "hannah.massenbauer@econ.uzh.ch", ///
    "anne.brenoe@econ.uzh.ch", ///
    "gianluca.spina@bluewin.ch", ///
    "cambriadaniele@gmail.com", ///
    "hannah.massenbauer@gmail.com", ///
    "daphne.rutnam@gmail.com") ///
    | strpos(RecipientEmail, "uzh.ch") > 0

* Drop test responses based on parent names if needed:
drop if inlist(RecipientFirstName, "test", "Test") | inlist(RecipientLastName, "test", "Test")

* Drop Qualtrics preview responses
drop if Status == 1

* Drop responses before the official start date
format StartDate %tc
drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms")

********************************************************************************
* 3. SENSITIVE DATA ONLY
********************************************************************************

preserve
    * Keep parent's sensitive information: ResponseId, IPAddress, location, 
    * RecipientEmail, RecipientFirstName, RecipientLastName
    keep ResponseId IPAddress LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName
    rename (LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName) ///
           (location_lat location_long par_email par_first_name par_last_name)
    destring location_lat location_long, replace
    save "${sensitive_data}/ps_par_sensitive_only.dta", replace
restore

* Drop sensitive variables from main dataset
drop IPAddress LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************

save "${processed_data}/PS_Parents/ps_par_all_anon.dta", replace

log close
