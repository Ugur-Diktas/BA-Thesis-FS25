# PS Data Cleaning Pipeline

This project implements a comprehensive data cleaning pipeline for two datasets:
- **PS_Students** (student survey data)
- **PS_Parents** (parent survey data)

The pipeline is implemented in Stata (version 18) and organised into a set of modular do‐files. The overall process cleans raw survey data, removes test responses and duplicates, anonymises sensitive information, recodes and relabels variables, merges external data (e.g. apprenticeship characteristics), and finally produces a clean dataset for analysis.

## Folder Structure

├── 1_data │ ├── backup │ ├── processed │ │ ├── PS_Parents │ │ │ ├── ps_par_all_anon.dta │ │ │ ├── ps_par_cleaned.dta │ │ │ └── temp_parents_step2.dta │ │ └── PS_Students │ │ ├── others_responses.xlsx │ │ ├── ps_stu_all_anon.dta │ │ ├── ps_stu_chars_merged.dta │ │ ├── ps_stu_clean_parent_occs.dta │ │ ├── ps_stu_cleaned.dta │ │ └── ps_stu_final.dta │ ├── raw │ ├── sensitive │ └── to_merge │ └── skill_intensity_data_with_apprentice_characteristics.dta ├── 2_code │ ├── 1_master.do │ ├── 2_globals.do │ ├── PS_Parents │ │ ├── 1_ps_parents_anonymize.do │ │ ├── 2_ps_parents_remove_duplicates.do │ │ ├── 3_ps_parents_clean_relabeling.do │ │ ├── 4_ps_parents_clean_beliefs.do │ │ ├── 5_ps_parents_clean_other.do │ │ ├── 6_ps_parents_merge_chars.do │ │ ├── 7_ps_parents_clean_parent_occs.do │ │ └── 8_ps_parents_drop_vars.do │ └── PS_Students │ ├── 1_ps_students_anonymize.do │ ├── 2_ps_students_remove_duplicates.do │ ├── 3_ps_students_clean_relabeling.do │ ├── 4_ps_students_clean_beliefs.do │ ├── 5_ps_students_clean_motivations.do │ ├── 6_ps_students_clean_other.do │ ├── 7_ps_students_clean_parent_occs.do │ ├── 8_ps_students_merge_chars.do │ └── 9_ps_students_drop_vars.do ├── 3_logfiles ├── 4_assets │ ├── Parental_occupation_cleaning_new │ └── clean_apprenticeships ├── 5_tests │ ├── run_tests.py │ ├── data_integrity_tests.py │ ├── edge_case_tests.do │ └── test_framework.py └── README.md

## Data Cleaning Pipeline Overview

The entire pipeline is orchestrated via the master do‐file (`1_master.do`), which sequentially calls all the cleaning scripts for both students and parents. The main steps are:

1. **Global Setup:**  
   - `2_globals.do` sets global paths and parameters (e.g. debug mode, folder paths).

2. **Data Import and Anonymisation:**  
   - **Students:** `1_ps_students_anonymize.do` imports all raw SPSS files, removes test responses, extracts sensitive data (saved separately), and saves an anonymised version.  
   - **Parents:** `1_ps_parents_anonymize.do` performs similar steps for the parent data.

3. **Duplicate Removal:**  
   - **Students:** `2_ps_students_remove_duplicates.do` removes duplicate responses (using ResponseId, email, and names) and retains only the final entry per group.  
   - **Parents:** `2_ps_parents_remove_duplicates.do` has been refactored to use the same logic.

4. **Relabelling and Recoding:**  
   - **Students:** `3_ps_students_clean_relabeling.do` recodes string variables to numeric, creates duration variables from click timestamps, standardises track/school variables, cleans free-text responses, and relabels variables.  
   - **Parents:** `3_ps_parents_clean_relabeling.do` now mirrors this approach, ensuring that duration, consent, and basic variables are handled consistently.

5. **Belief and Motivation Variables:**  
   - **Students:** `4_ps_students_clean_beliefs.do` reshapes and standardises belief‐related responses (e.g. marriage probability, parental approvals) and calculates gender‐consistent averages.  
   - **Parents:** `4_ps_parents_clean_beliefs.do` has been refactored to replicate these mechanisms for parent responses.

6. **Motivational Factors Processing:**  
   - **Students:** `5_ps_students_clean_motivations.do` maps motivational factor responses to predefined factor numbers and labels them.  
   - **Parents:** Similar processing is applied where relevant.

7. **Cleaning of “Other” Free-Text Fields:**  
   - **Students:** `6_ps_students_clean_other.do` cleans and standardises free-text apprenticeship responses and produces a review table in Excel.  
   - **Parents:** `5_ps_parents_clean_other.do` (and subsequent steps) follow an analogous procedure.

8. **Merging with External Characteristics Data:**  
   - **Students:** `8_ps_students_merge_chars.do` merges apprenticeship characteristics (e.g. skill intensity, female share) using a coded key.  
   - **Parents:** `6_ps_parents_merge_chars.do` now performs similar merges with external datasets.

9. **Parent Occupation Cleaning:**  
   - **Students:** `7_ps_students_clean_parent_occs.do` cleans parent occupation text entries using preliminary string matching and manual review (with an Excel crosswalk).  
   - **Parents:** `7_ps_parents_clean_parent_occs.do` has been refactored to follow the same logic.

10. **Final Variable Dropping and Dataset Preparation:**  
    - **Students:** `9_ps_students_drop_vars.do` drops unnecessary metadata and intermediate variables, producing the final cleaned dataset.  
    - **Parents:** `8_ps_parents_drop_vars.do` does likewise.

## How to Run the Code

1. **Pre-requisites:**  
   - Install Stata 18.
   - Ensure all global paths are correctly set in `2_globals.do` (update according to your file system).
   - Place the raw data files in the `1_data/raw` folder.
   - Ensure that external Excel files (for apprenticeship and parental occupation cleaning) are in their designated folders.

2. **Running the Pipeline:**  
   - Open Stata and change the working directory to the project root.
   - Run the master do‐file:  
     ```
     do 2_code/1_master.do
     ```
   - Logs will be generated in the `3_logfiles` directory.

3. **Running the Tests:**  
   - Run the test scripts (for example, using Python with `5_tests/run_tests.py` or by executing the `edge_case_tests.do` file in Stata) to ensure all steps function as intended.

## Testing and Data Integrity

- The new test scripts create mock datasets to simulate the cleaning steps and check:
  - That the number of observations remains consistent.
  - That all critical variables are retained or correctly transformed.
  - That duplicate and test responses are removed only when intended.
- Refer to the documentation in the `5_tests` folder for further details on how each test is implemented.

## Excel File Improvements

- **clean_apprenticeships.xlsx:**  
  - Sheet names are now clearly labelled as “Uncleaned Responses”, “Manual Cleaning”, and “Final Crosswalk”.
  - A metadata sheet explains the meaning of each column.
- **clean occupations.xlsx:**  
  - Contains instructions on how to perform manual review.
  - Headers and cell formatting have been standardised for clarity.

## Code Conventions

- All files follow the same structure:
  - Header block with purpose, usage, and version info.
  - Section dividers (using asterisks or dashed lines) to separate logic blocks.
  - Consistent use of local macros and error handling.
- Comments have been updated to be explanatory, so that a new user can follow the data flow without needing prior project knowledge.

## Additional Information

- **Sensitive Data Handling:**  
  Sensitive variables (e.g. email addresses, IP addresses) are separated and stored in the `1_data/sensitive` folder before being dropped from the working dataset.
- **Merging and External Data:**  
  The external datasets (e.g. apprenticeship characteristics) are merged using a common key (LABB codes) and standardised immediately after merging.
- **Future Extensions:**  
  The testing framework and modular code design allow for easy addition of new cleaning steps or modifications without breaking existing functionality.

## Authors & Contact

- **Ugur Diktas-Jelke Clarysse**  
  BA Thesis FS25, 2025  
- For any questions or further clarifications, please contact the project authors.

---

By following these instructions and using the newly refactored code, any analyst—even one unfamiliar with the project—should be able to understand and reproduce the cleaning process for both the student and parent datasets.

---

### Final Note

All changes have been made with care to preserve the original functionality while greatly enhancing readability, maintainability, and testability. Please review the updated test logs in the `3_logfiles/test_logs` folder to verify the integrity of each processing step.

---

*End of README.md*
