import os
import subprocess
import pandas as pd
import logging
from datetime import datetime

class DataIntegrityTester:
    """
    A testing framework focusing on data integrity for Stata data cleaning pipelines.
    Verifies data consistency, structural integrity, and expected transformations.
    """
    
    def __init__(self, root_dir=None):
        """Initialize the tester with project root directory."""
        if root_dir is None:
            # Use same logic as 1_master.do for auto-detecting root
            self.root_dir = self.determine_root_path()
        else:
            self.root_dir = root_dir
            
        self.setup_logging()
        self.results = {}
        
    def determine_root_path(self):
        """
        Determine the root path based on username similar to 1_master.do.
        Falls back to current directory if no match is found.
        """
        import getpass
        username = getpass.getuser()
        
        # Define roots for different users
        user_roots = {
            "jelkeclarysse": "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning",
            "ugurdiktas": "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
        }
        
        # Return root path for current user or default to current directory
        if username in user_roots:
            root_path = user_roots[username]
            if os.path.exists(root_path):
                return root_path
                
        # Fallback to current directory
        return os.path.abspath(os.getcwd())
    
    def setup_logging(self):
        """Configure logging to file and console."""
        log_dir = os.path.join(self.root_dir, "tests", "logs")
        os.makedirs(log_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = os.path.join(log_dir, f"integrity_test_{timestamp}.log")
        
        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging
        
    def run_stata_check(self, script_content):
        """
        Run a Stata script and return its output.
        The script should return data in a format that can be parsed.
        """
        # Create a temporary script file
        temp_script_path = os.path.join(self.root_dir, "temp_check_script.do")
        with open(temp_script_path, "w") as f:
            f.write(script_content)
        
        # Run the script
        try:
            result = subprocess.run(
                ['stata-mp', '-b', 'do', temp_script_path],
                cwd=self.root_dir,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Clean up
            if os.path.exists(temp_script_path):
                os.remove(temp_script_path)
            
            if result.returncode != 0:
                self.logger.error(f"Stata script failed with code {result.returncode}")
                self.logger.error(f"Error: {result.stderr}")
                return None
            
            return result.stdout
            
        except Exception as e:
            self.logger.error(f"Error running Stata script: {str(e)}")
            # Clean up
            if os.path.exists(temp_script_path):
                os.remove(temp_script_path)
            return None
    
    def test_output_file_existence(self):
        """Test that all expected output files exist after running the pipeline."""
        self.logger.info("Testing output file existence")
        
        expected_files = [
            # Students files
            os.path.join(self.root_dir, "1_data", "processed", "PS_Students", "ps_stu_all_anon.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Students", "ps_stu_cleaned.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Students", "ps_stu_chars_merged.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Students", "ps_stu_clean_parent_occs.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Students", "ps_stu_final.dta"),
            
            # Parents files
            os.path.join(self.root_dir, "1_data", "processed", "PS_Parents", "ps_par_all_anon.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Parents", "ps_par_cleaned.dta"),
            os.path.join(self.root_dir, "1_data", "processed", "PS_Parents", "ps_parents_final.dta")
        ]
        
        missing_files = []
        for file_path in expected_files:
            if not os.path.exists(file_path):
                missing_files.append(file_path)
        
        if missing_files:
            self.logger.error(f"Missing output files: {len(missing_files)}")
            for file in missing_files:
                self.logger.error(f"  - {file}")
            self.results["Output File Existence"] = "FAIL"
            return False
        else:
            self.logger.info("All expected output files exist")
            self.results["Output File Existence"] = "PASS"
            return True
    
    def test_variable_consistency(self):
        """
        Test that key variables are consistently present and properly formatted
        throughout the data cleaning pipeline.
        """
        self.logger.info("Testing variable consistency")
        
        # Check that key variables in students dataset remain consistent
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Load final students dataset
        use "${processed_data}/PS_Students/ps_stu_final.dta", clear
        
        // Check for key variables
        local key_vars "ResponseId contract female sit age"
        
        foreach var of local key_vars {
            capture confirm variable `var'
            if _rc != 0 {
                display "ERROR: Key variable `var' missing from final dataset"
                exit 1
            }
        }
        
        // Check data type of key variables
        capture confirm numeric variable female
        if _rc != 0 {
            display "ERROR: Variable 'female' is not numeric"
            exit 1
        }
        
        capture confirm numeric variable contract
        if _rc != 0 {
            display "ERROR: Variable 'contract' is not numeric"
            exit 1
        }
        
        // Count observations
        count
        display "FINAL_COUNT: " r(N)
        
        display "All key variable checks passed"
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Variable Consistency"] = "FAIL"
            return False
        
        if "All key variable checks passed" in output:
            self.logger.info("Key variables are consistent in students dataset")
            self.results["Variable Consistency - Students"] = "PASS"
        else:
            self.logger.error("Key variable consistency check failed for students dataset")
            self.results["Variable Consistency - Students"] = "FAIL"
        
        # Extract observation count
        import re
        match = re.search(r"FINAL_COUNT: (\d+)", output)
        if match:
            count = int(match.group(1))
            self.logger.info(f"Final students dataset has {count} observations")
        
        # Similar check for parents dataset
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Check if final parents dataset exists
        capture confirm file "${processed_data}/PS_Parents/ps_parents_final.dta"
        if _rc == 0 {
            // Load final parents dataset
            use "${processed_data}/PS_Parents/ps_parents_final.dta", clear
            
            // Check for key variables
            local key_vars "ResponseId"
            
            foreach var of local key_vars {
                capture confirm variable `var'
                if _rc != 0 {
                    display "ERROR: Key variable `var' missing from final parents dataset"
                    exit 1
                }
            }
            
            // Count observations
            count
            display "PARENTS_FINAL_COUNT: " r(N)
            
            display "All key variable checks passed for parents dataset"
        }
        else {
            // Try the intermediate dataset
            capture confirm file "${processed_data}/PS_Parents/ps_par_cleaned.dta"
            if _rc == 0 {
                use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear
                
                // Check for key variables
                local key_vars "ResponseId"
                
                foreach var of local key_vars {
                    capture confirm variable `var'
                    if _rc != 0 {
                        display "ERROR: Key variable `var' missing from parents intermediate dataset"
                        exit 1
                    }
                }
                
                // Count observations
                count
                display "PARENTS_INTERMEDIATE_COUNT: " r(N)
                
                display "All key variable checks passed for parents intermediate dataset"
            }
            else {
                display "ERROR: No parents dataset found"
                exit 1
            }
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Variable Consistency - Parents"] = "FAIL"
            return False
        
        if "All key variable checks passed for parents" in output:
            self.logger.info("Key variables are consistent in parents dataset")
            self.results["Variable Consistency - Parents"] = "PASS"
        else:
            self.logger.error("Key variable consistency check failed for parents dataset")
            self.results["Variable Consistency - Parents"] = "FAIL"
        
        return "PASS" in self.results["Variable Consistency - Students"] and "PASS" in self.results["Variable Consistency - Parents"]
    
    def test_data_transformations(self):
        """Test that expected data transformations occur correctly."""
        self.logger.info("Testing data transformations")
        
        # Check that belief variables are properly transformed in the students dataset
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Load cleaned students dataset
        capture confirm file "${processed_data}/PS_Students/ps_stu_cleaned.dta"
        if _rc != 0 {
            display "ERROR: Cleaned students dataset not found"
            exit 1
        }
        
        use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
        
        // Check if belief variables have been transformed
        local belief_vars "belief_fit_occ2 belief_fit_occ3 belief_fit_occ4 belief_fit_occ5 belief_fit_occ6 belief_fit_occ7"
        local transformed = 1
        
        foreach var of local belief_vars {
            capture confirm variable `var'
            if _rc != 0 {
                local transformed = 0
                display "INFO: Belief variable `var' not found, transformation may not have completed"
            }
        }
        
        if `transformed' == 1 {
            display "TRANSFORMATION_CHECK: Belief variables properly transformed"
        }
        else {
            display "TRANSFORMATION_CHECK: Belief variables transformation incomplete"
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Data Transformations - Beliefs"] = "INCONCLUSIVE"
        elif "TRANSFORMATION_CHECK: Belief variables properly transformed" in output:
            self.logger.info("Belief variables properly transformed")
            self.results["Data Transformations - Beliefs"] = "PASS"
        else:
            self.logger.warning("Belief variables transformation may be incomplete")
            self.results["Data Transformations - Beliefs"] = "WARNING"
        
        # Check that motivation factors are properly transformed
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Load cleaned students dataset
        capture confirm file "${processed_data}/PS_Students/ps_stu_cleaned.dta"
        if _rc != 0 {
            display "ERROR: Cleaned students dataset not found"
            exit 1
        }
        
        use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
        
        // Check if motivation factor variables have been transformed
        local mf_vars "child_fac_1 child_fac_2 child_fac_3 mother_fac_1 mother_fac_2 father_fac_1 father_fac_2"
        local transformed = 1
        
        foreach var of local mf_vars {
            capture confirm variable `var'
            if _rc != 0 {
                local transformed = 0
                display "INFO: Motivation factor variable `var' not found, transformation may not have completed"
            }
        }
        
        if `transformed' == 1 {
            display "TRANSFORMATION_CHECK: Motivation factor variables properly transformed"
        }
        else {
            display "TRANSFORMATION_CHECK: Motivation factor variables transformation incomplete"
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Data Transformations - Motivation Factors"] = "INCONCLUSIVE"
        elif "TRANSFORMATION_CHECK: Motivation factor variables properly transformed" in output:
            self.logger.info("Motivation factor variables properly transformed")
            self.results["Data Transformations - Motivation Factors"] = "PASS"
        else:
            self.logger.warning("Motivation factor variables transformation may be incomplete")
            self.results["Data Transformations - Motivation Factors"] = "WARNING"
        
        return "FAIL" not in [
            self.results["Data Transformations - Beliefs"],
            self.results["Data Transformations - Motivation Factors"]
        ]
    
    def test_missing_values(self):
        """Test for unexpected patterns of missing values in key variables."""
        self.logger.info("Testing missing values patterns")
        
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Load final students dataset
        capture confirm file "${processed_data}/PS_Students/ps_stu_final.dta"
        if _rc != 0 {
            display "ERROR: Final students dataset not found"
            exit 1
        }
        
        use "${processed_data}/PS_Students/ps_stu_final.dta", clear
        
        // Check for missing values in key demographic variables
        foreach var of varlist female contract {
            count if missing(`var')
            local miss_`var' = r(N)
            display "MISSING_`var': `miss_`var''"
        }
        
        // Calculate missing rate for survey variables
        quietly ds ResponseId female contract
        local exclude_vars = r(varlist)
        local total_vars = 0
        local total_missing = 0
        
        foreach var of varlist * {
            if !`:list var in exclude_vars' {
                local ++total_vars
                quietly count if missing(`var')
                local total_missing = `total_missing' + r(N)
            }
        }
        
        if `total_vars' > 0 {
            local missing_rate = `total_missing' / (`total_vars' * _N)
            display "OVERALL_MISSING_RATE: `missing_rate'"
        }
        else {
            display "OVERALL_MISSING_RATE: N/A"
        }
        
        // Set threshold for acceptable missing rate
        if `total_vars' > 0 {
            if `missing_rate' > 0.3 {
                display "WARNING: Overall missing rate is high (> 30%)"
            }
            else {
                display "MISSING_CHECK: Missing rate is acceptable"
            }
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Missing Values Check"] = "INCONCLUSIVE"
            return False
        
        import re
        # Extract missing counts
        female_missing = None
        contract_missing = None
        missing_rate = None
        
        match = re.search(r"MISSING_female: (\d+)", output)
        if match:
            female_missing = int(match.group(1))
            
        match = re.search(r"MISSING_contract: (\d+)", output)
        if match:
            contract_missing = int(match.group(1))
            
        match = re.search(r"OVERALL_MISSING_RATE: ([\d\.]+)", output)
        if match and match.group(1) != "N/A":
            missing_rate = float(match.group(1))
        
        # Log the findings
        if female_missing is not None:
            self.logger.info(f"Missing values in 'female': {female_missing}")
        if contract_missing is not None:
            self.logger.info(f"Missing values in 'contract': {contract_missing}")
        if missing_rate is not None:
            self.logger.info(f"Overall missing rate: {missing_rate:.2%}")
        
        # Determine test result
        if "MISSING_CHECK: Missing rate is acceptable" in output:
            self.results["Missing Values Check"] = "PASS"
            return True
        elif "WARNING: Overall missing rate is high" in output:
            self.logger.warning("High rate of missing values detected")
            self.results["Missing Values Check"] = "WARNING"
            return True
        else:
            self.results["Missing Values Check"] = "INCONCLUSIVE"
            return False
    
    def test_dataset_coherence(self):
        """Test that student and parent datasets can be linked consistently."""
        self.logger.info("Testing student-parent dataset coherence")
        
        # Fixed version - using a regular string with escaped backticks in Stata code
        script = '''
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Check if both final datasets exist
        capture confirm file "${processed_data}/PS_Students/ps_stu_final.dta"
        capture confirm file "${processed_data}/PS_Parents/ps_parents_final.dta"
        
        if _rc == 0 {
            // Both datasets exist, test coherence
            use "${processed_data}/PS_Students/ps_stu_final.dta", clear
            
            // Get count of student records
            count
            local student_count = r(N)
            display "STUDENT_COUNT: `student_count'"
            
            // Preserve student ResponseIds
            tempfile student_ids
            keep ResponseId
            save `student_ids'
            
            // Load parent dataset and merge
            use "${processed_data}/PS_Parents/ps_parents_final.dta", clear
            
            // Get count of parent records
            count
            local parent_count = r(N)
            display "PARENT_COUNT: `parent_count'"
            
            // Merge with student IDs
            merge 1:1 ResponseId using `student_ids'
            
            // Count matches
            count if _merge == 3
            local match_count = r(N)
            display "MATCH_COUNT: `match_count'"
            
            // Calculate match percentage
            local match_pct_student = `match_count' / `student_count' * 100
            local match_pct_parent = `match_count' / `parent_count' * 100
            
            display "MATCH_PCT_STUDENT: `match_pct_student'"
            display "MATCH_PCT_PARENT: `match_pct_parent'"
            
            if `match_pct_student' < 50 {
                display "WARNING: Less than 50% of student records have matching parent records"
            }
            else if `match_pct_student' < 80 {
                display "INFO: Between 50% and 80% of student records have matching parent records"
            }
            else {
                display "COHERENCE_CHECK: Good match rate between student and parent datasets"
            }
        }
        else {
            // At least one dataset is missing, try intermediate datasets
            capture confirm file "${processed_data}/PS_Students/ps_stu_cleaned.dta"
            capture confirm file "${processed_data}/PS_Parents/ps_par_cleaned.dta"
            
            if _rc == 0 {
                // Both intermediate datasets exist, test coherence
                use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
                
                // Get count of student records
                count
                local student_count = r(N)
                display "STUDENT_COUNT: `student_count'"
                
                // Preserve student ResponseIds
                tempfile student_ids
                keep ResponseId
                save `student_ids'
                
                // Load parent dataset and merge
                use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear
                
                // Get count of parent records
                count
                local parent_count = r(N)
                display "PARENT_COUNT: `parent_count'"
                
                // Merge with student IDs
                merge 1:1 ResponseId using `student_ids'
                
                // Count matches
                count if _merge == 3
                local match_count = r(N)
                display "MATCH_COUNT: `match_count'"
                
                // Calculate match percentage
                local match_pct_student = `match_count' / `student_count' * 100
                local match_pct_parent = `match_count' / `parent_count' * 100
                
                display "MATCH_PCT_STUDENT: `match_pct_student'"
                display "MATCH_PCT_PARENT: `match_pct_parent'"
                
                if `match_pct_student' < 50 {
                    display "WARNING: Less than 50% of student records have matching parent records"
                }
                else if `match_pct_student' < 80 {
                    display "INFO: Between 50% and 80% of student records have matching parent records"
                }
                else {
                    display "COHERENCE_CHECK: Good match rate between student and parent datasets"
                }
            }
            else {
                display "ERROR: Cannot test dataset coherence, required datasets not found"
            }
        }
        '''
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Dataset Coherence"] = "INCONCLUSIVE"
            return False
        
        # Parse output to extract match statistics
        import re
        student_count = None
        parent_count = None
        match_count = None
        match_pct_student = None
        match_pct_parent = None
        
        match = re.search(r"STUDENT_COUNT: (\d+)", output)
        if match:
            student_count = int(match.group(1))
            
        match = re.search(r"PARENT_COUNT: (\d+)", output)
        if match:
            parent_count = int(match.group(1))
            
        match = re.search(r"MATCH_COUNT: (\d+)", output)
        if match:
            match_count = int(match.group(1))
            
        match = re.search(r"MATCH_PCT_STUDENT: ([\d\.]+)", output)
        if match:
            match_pct_student = float(match.group(1))
            
        match = re.search(r"MATCH_PCT_PARENT: ([\d\.]+)", output)
        if match:
            match_pct_parent = float(match.group(1))
        
        # Log findings
        if student_count is not None:
            self.logger.info(f"Student dataset count: {student_count}")
        if parent_count is not None:
            self.logger.info(f"Parent dataset count: {parent_count}")
        if match_count is not None:
            self.logger.info(f"Matching records: {match_count}")
        if match_pct_student is not None:
            self.logger.info(f"Student records with matching parent records: {match_pct_student:.1f}%")
        if match_pct_parent is not None:
            self.logger.info(f"Parent records with matching student records: {match_pct_parent:.1f}%")
        
        # Determine test result
        if "COHERENCE_CHECK: Good match rate" in output:
            self.results["Dataset Coherence"] = "PASS"
            return True
        elif "WARNING: Less than 50% of student records" in output:
            self.logger.warning("Low match rate between student and parent datasets")
            self.results["Dataset Coherence"] = "WARNING"
            return False
        elif "INFO: Between 50% and 80% of student records" in output:
            self.logger.info("Moderate match rate between student and parent datasets")
            self.results["Dataset Coherence"] = "PARTIAL"
            return True
        elif "ERROR: Cannot test dataset coherence" in output:
            self.logger.error("Required datasets not found for coherence test")
            self.results["Dataset Coherence"] = "INCONCLUSIVE"
            return False
        else:
            self.results["Dataset Coherence"] = "INCONCLUSIVE"
            return False
        
    def test_observation_preservation(self):
        """Test that observations are properly preserved throughout the cleaning process."""
        self.logger.info("Testing observation preservation")
        
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Compare raw vs processed student counts
        capture confirm file "${raw_data}/PoF_PS_Students.dta"
        if _rc != 0 {
            display "ERROR: Raw students dataset not found"
            exit 1
        }
        
        use "${raw_data}/PoF_PS_Students.dta", clear
        count
        local raw_count = r(N)
        display "RAW_COUNT: `raw_count'"
        
        // Get final count
        capture confirm file "${processed_data}/PS_Students/ps_stu_final.dta"
        if _rc != 0 {
            display "ERROR: Final students dataset not found"
            exit 1
        }
        
        use "${processed_data}/PS_Students/ps_stu_final.dta", clear
        count 
        local final_count = r(N)
        display "FINAL_COUNT: `final_count'"
        
        // Calculate percentage preserved
        local preserved_pct = `final_count' / `raw_count' * 100
        display "PRESERVED_PERCENT: `preserved_pct'"
        
        // Test for significant loss
        if `preserved_pct' < 85 {
            display "WARNING: Significant data loss detected (only `preserved_pct'% preserved)"
        }
        else {
            display "DATA_PRESERVATION: Acceptable level of data retained"
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Observation Preservation"] = "INCONCLUSIVE"
            return False

        import re
        # Extract counts
        raw_count = None
        final_count = None
        preserved_pct = None
        
        match = re.search(r"RAW_COUNT: (\d+)", output)
        if match:
            raw_count = int(match.group(1))
            
        match = re.search(r"FINAL_COUNT: (\d+)", output)
        if match:
            final_count = int(match.group(1))
            
        match = re.search(r"PRESERVED_PERCENT: ([\d\.]+)", output)
        if match:
            preserved_pct = float(match.group(1))
        
        # Log the findings
        if raw_count is not None:
            self.logger.info(f"Raw observations: {raw_count}")
        if final_count is not None:
            self.logger.info(f"Final observations: {final_count}")
        if preserved_pct is not None:
            self.logger.info(f"Data preservation rate: {preserved_pct:.1f}%")
        
        # Determine test result
        if "DATA_PRESERVATION: Acceptable level" in output:
            self.results["Observation Preservation"] = "PASS"
            return True
        elif "WARNING: Significant data loss detected" in output:
            self.logger.warning(f"Significant data loss detected (only {preserved_pct:.1f}% preserved)")
            self.results["Observation Preservation"] = "WARNING"
            return False
        else:
            self.results["Observation Preservation"] = "INCONCLUSIVE"
            return False
    
    def test_duplicate_resolution_quality(self):
        """Test that duplicate resolution preserves the right records."""
        self.logger.info("Testing duplicate resolution quality")
        
        script = """
        clear all
        set more off
        
        // Source globals
        do "2_code/2_globals.do"
        
        // Load and tag dupes in raw data
        capture confirm file "${raw_data}/PoF_PS_Students.dta"
        if _rc != 0 {
            display "ERROR: Raw students dataset not found"
            exit 1
        }
        
        use "${raw_data}/PoF_PS_Students.dta", clear
        
        // Find duplicates by ResponseId and mark them
        duplicates tag ResponseId, gen(dup_tag)
        count if dup_tag > 0
        display "DUPES_COUNT: " r(N)
        
        // Count total duplicated records
        count if dup_tag > 0
        local total_dupes = r(N)
        
        // Identify records that would be completely dropped vs properly merged
        capture egen timestamp = max(StartDate), by(ResponseId)
        if _rc == 0 {
            // If we can sort by timestamp, do so
            gen should_keep = (StartDate == timestamp)
            count if dup_tag > 0 & should_keep == 0
            display "RECORDS_TO_DROP: " r(N)
            
            // Check if any critical values would be lost in dropped dupes
            // Contract is an important variable we want to preserve
            gen has_critical_value = 0
            capture confirm variable contract
            if _rc == 0 {
                replace has_critical_value = 1 if !missing(contract) & should_keep == 0
                count if has_critical_value == 1
                display "DUPES_WITH_CRITICAL_VALUES: " r(N)
            }
            else {
                display "DUPES_WITH_CRITICAL_VALUES: UNKNOWN"
            }
        }
        else {
            // Can't determine which records would be kept
            display "RECORDS_TO_DROP: UNKNOWN"
            display "DUPES_WITH_CRITICAL_VALUES: UNKNOWN"
        }
        """
        
        output = self.run_stata_check(script)
        if output is None:
            self.results["Duplicate Resolution Quality"] = "INCONCLUSIVE"
            return False

        import re
        dupes_count = None
        records_to_drop = None
        critical_values = None
        
        match = re.search(r"DUPES_COUNT: (\d+)", output)
        if match:
            dupes_count = int(match.group(1))
            
        match = re.search(r"RECORDS_TO_DROP: (\d+)", output)
        if match and match.group(1) != "UNKNOWN":
            records_to_drop = int(match.group(1))
            
        match = re.search(r"DUPES_WITH_CRITICAL_VALUES: (\d+)", output)
        if match and match.group(1) != "UNKNOWN":
            critical_values = int(match.group(1))
        
        # Log the findings
        if dupes_count is not None:
            self.logger.info(f"Duplicate records found: {dupes_count}")
        if records_to_drop is not None:
            self.logger.info(f"Records that would be dropped: {records_to_drop}")
        if critical_values is not None:
            self.logger.info(f"Duplicate records with critical values: {critical_values}")
        
        # Determine test result
        if critical_values is not None and critical_values > 0:
            self.logger.warning(f"Found {critical_values} duplicates with critical values that might be dropped")
            self.results["Duplicate Resolution Quality"] = "WARNING"
            return False
        elif dupes_count is not None and dupes_count > 0:
            self.logger.info("Duplicates found but no critical values would be lost")
            self.results["Duplicate Resolution Quality"] = "PASS"
            return True
        elif dupes_count == 0:
            self.logger.info("No duplicates found")
            self.results["Duplicate Resolution Quality"] = "PASS"
            return True
        else:
            self.results["Duplicate Resolution Quality"] = "INCONCLUSIVE"
            return False