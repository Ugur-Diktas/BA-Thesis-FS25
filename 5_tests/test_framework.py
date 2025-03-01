import os
import subprocess
import logging
import time
from datetime import datetime
import getpass

class DataCleaningTester:
    """
    A testing framework for Stata data cleaning pipelines.
    Tests individual do-files, dataset pipelines, and the entire process.
    """
    
    def __init__(self, root_dir=None):
        """Initialize the tester with project root directory."""
        if root_dir is None:
            # Use same logic as 1_master.do for auto-detecting root
            self.root_dir = self.determine_root_path()
        else:
            self.root_dir = root_dir
            
        self.setup_logging()
        self.stata_cmd = self.determine_stata_command()
        
    def determine_root_path(self):
        """
        Determine the root path based on username similar to 1_master.do.
        Falls back to current directory if no match is found.
        """
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

    def determine_stata_command(self):
        """
        Find the appropriate Stata command for the current system.
        Tries various common Stata executable names and locations.
        """
        username = getpass.getuser()
        
        # Define user-specific Stata commands
        user_stata_commands = {
            "jelkeclarysse": "stata-mp",
            "ugurdiktas": "/Applications/Stata/StataBE.app/Contents/MacOS/stataBE"  # Set exact path for ugurdiktas
        }
        
        # Return specific command for current user if it exists
        if username in user_stata_commands:
            return user_stata_commands[username]
        
        # Check for common Mac Stata installations for Apple Silicon
        mac_specific_paths = [
            "/Applications/Stata/StataBE.app/Contents/MacOS/stataBE",
            "/Applications/Stata/StataSE.app/Contents/MacOS/stataSE",
            "/Applications/Stata/StataMP.app/Contents/MacOS/stataMP",
            "/Applications/Stata/Stata.app/Contents/MacOS/stata"
        ]
        
        for path in mac_specific_paths:
            if os.path.exists(path):
                return path
        
        # Try to locate Stata executable in common locations
        possible_commands = ["stata", "stata-se", "stata-mp", "stata-be", "StataMP-64", "StataMP", "StataSE-64", "StataSE", "StataBE"]
        
        # Windows-specific paths
        if os.name == 'nt':
            program_files = os.environ.get('PROGRAMFILES', 'C:\\Program Files')
            stata_paths = [
                os.path.join(program_files, "Stata18", cmd + ".exe") for cmd in ["StataSE-64", "StataMP-64", "Stata-64", "StataBE-64"]
            ] + [
                os.path.join(program_files, "Stata17", cmd + ".exe") for cmd in ["StataSE-64", "StataMP-64", "Stata-64", "StataBE-64"]
            ]
            
            for path in stata_paths:
                if os.path.exists(path):
                    return f'"{path}"'  # Return with quotes for paths with spaces
        
        # For macOS/Linux, try commands directly (should be in PATH)
        for cmd in possible_commands:
            try:
                # Check if command exists by running 'which' or 'where'
                if os.name == 'nt':
                    check_cmd = ["where", cmd]
                else:
                    check_cmd = ["which", cmd]
                
                result = subprocess.run(check_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if result.returncode == 0:
                    return cmd
            except:
                pass
        
        # Default to stata-se if nothing else is found
        return "stata-se"
        
    def setup_logging(self):
        """Configure logging to file and console."""
        log_dir = os.path.join(self.root_dir, "3_logfiles", "test_logs")
        os.makedirs(log_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = os.path.join(log_dir, f"test_run_{timestamp}.log")
        
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
        self.logger.info(f"Test run started at {timestamp}")
        self.logger.info(f"Root directory: {self.root_dir}")
    
    def run_stata_command(self, command, cwd=None):
        """Run a Stata command through the command line."""
        if cwd is None:
            cwd = self.root_dir
            
        self.logger.info(f"Running Stata command: {command}")
        self.logger.info(f"Working directory: {cwd}")
        
        try:
            if os.path.exists(self.stata_cmd):
                # Full path to Stata executable
                cmd_parts = [self.stata_cmd, "-b", "-e", "do", command]
            elif self.stata_cmd.startswith('"') and self.stata_cmd.endswith('"'):
                # Windows path with quotes
                cmd_parts = [self.stata_cmd.strip('"'), "-b", "-e", "do", command]
            else:
                # Just the command name
                cmd_parts = [self.stata_cmd, "-b", "-e", "do", command]
                
            self.logger.info(f"Using Stata command: {self.stata_cmd}")
            
            result = subprocess.run(
                cmd_parts,
                cwd=cwd,
                capture_output=True,
                text=True,
                check=False
            )
                
            if result.returncode != 0:
                self.logger.error(f"Stata command failed with return code {result.returncode}")
                self.logger.error(f"Error output: {result.stderr}")
                return False, result.stderr
            else:
                self.logger.info(f"Stata command completed successfully")
                return True, result.stdout
                
        except Exception as e:
            self.logger.error(f"Error running Stata command: {str(e)}")
            return False, str(e)
    
    def test_individual_dofile(self, dofile_path):
        """Test a single do-file in isolation."""
        # First, generate a temporary test script that sources globals and runs the target do-file
        test_script = f"""
        clear all
        set more off
        
        // Source globals
        do "{os.path.join(self.root_dir, '2_code', '2_globals.do')}"
        
        // Run target do-file
        do "{dofile_path}"
        
        // Check for errors
        if _rc != 0 {{
            display "ERROR: Do-file execution failed with code " _rc
            exit _rc
        }}
        else {{
            display "SUCCESS: Do-file executed without errors"
        }}
        """
        
        # Write the test script to a temporary file
        temp_script_path = os.path.join(self.root_dir, "temp_test_script.do")
        with open(temp_script_path, "w") as f:
            f.write(test_script)
        
        # Run the temporary script
        self.logger.info(f"Testing individual do-file: {dofile_path}")
        success, output = self.run_stata_command(temp_script_path)
        
        # Clean up
        if os.path.exists(temp_script_path):
            os.remove(temp_script_path)
        
        return success, output
    
    def test_student_pipeline(self):
        """Test the entire student data cleaning pipeline."""
        return self._test_dataset_pipeline("PS_Students")
    
    def test_parent_pipeline(self):
        """Test the entire parent data cleaning pipeline."""
        return self._test_dataset_pipeline("PS_Parents")
    
    def _test_dataset_pipeline(self, dataset_folder):
        """Test all do-files for a specific dataset in sequence."""
        self.logger.info(f"Testing {dataset_folder} pipeline")
        
        # Create a temporary script that runs all do-files in order
        dataset_dir = os.path.join(self.root_dir, "2_code", dataset_folder)
        
        if not os.path.exists(dataset_dir):
            self.logger.error(f"Dataset directory not found: {dataset_dir}")
            return False, f"Directory not found: {dataset_dir}"
        
        # Get all do-files sorted by filename
        dofiles = sorted([
            f for f in os.listdir(dataset_dir) 
            if f.endswith(".do") and not f.startswith("_")
        ])
        
        if not dofiles:
            self.logger.error(f"No do-files found in {dataset_dir}")
            return False, f"No do-files found in {dataset_dir}"
        
        # Create a temporary script that runs all do-files in order
        test_script = f"""
        clear all
        set more off
        
        // Source globals
        do "{os.path.join(self.root_dir, '2_code', '2_globals.do')}"
        
        // Set error action
        set errcontinue, break
        
        // Run all do-files in sequence
        """
        
        for dofile in dofiles:
            test_script += f"""
        display _newline
        display "--------------------------------------------------------"
        display "Running do-file: {dofile}"
        display "--------------------------------------------------------"
        do "{os.path.join(dataset_dir, dofile)}"
        if _rc != 0 {{
            display "ERROR: Do-file {dofile} execution failed with code " _rc
            exit _rc
        }}
        """
        
        test_script += """
        display _newline
        display "SUCCESS: All do-files executed without errors"
        """
        
        # Write the test script to a temporary file
        temp_script_path = os.path.join(self.root_dir, f"temp_test_{dataset_folder}.do")
        with open(temp_script_path, "w") as f:
            f.write(test_script)
        
        # Run the temporary script
        success, output = self.run_stata_command(temp_script_path)
        
        # Clean up
        if os.path.exists(temp_script_path):
            os.remove(temp_script_path)
        
        return success, output
    
    def test_full_pipeline(self):
        """Test the entire data cleaning process using the master do-file."""
        master_dofile = os.path.join(self.root_dir, "2_code", "1_master.do")
        
        if not os.path.exists(master_dofile):
            self.logger.error(f"Master do-file not found: {master_dofile}")
            return False, f"File not found: {master_dofile}"
        
        self.logger.info("Testing full data cleaning pipeline")
        return self.run_stata_command(master_dofile)
    
    def run_all_tests(self):
        """Run all tests and produce a summary report."""
        start_time = time.time()
        self.logger.info("Starting complete test suite")
        
        # Keep track of test results
        results = {}
        
        # Test student pipeline
        self.logger.info("-" * 80)
        self.logger.info("TESTING STUDENT PIPELINE")
        self.logger.info("-" * 80)
        success, output = self.test_student_pipeline()
        results["Student Pipeline"] = "PASS" if success else "FAIL"
        
        # Test parent pipeline
        self.logger.info("-" * 80)
        self.logger.info("TESTING PARENT PIPELINE")
        self.logger.info("-" * 80)
        success, output = self.test_parent_pipeline()
        results["Parent Pipeline"] = "PASS" if success else "FAIL"
        
        # Test individual do-files
        self.logger.info("-" * 80)
        self.logger.info("TESTING INDIVIDUAL DO-FILES")
        self.logger.info("-" * 80)
        
        # Test each student do-file
        student_dofiles_dir = os.path.join(self.root_dir, "2_code", "PS_Students")
        if os.path.exists(student_dofiles_dir):
            for dofile in sorted(os.listdir(student_dofiles_dir)):
                if dofile.endswith(".do") and not dofile.startswith("_"):
                    dofile_path = os.path.join(student_dofiles_dir, dofile)
                    success, _ = self.test_individual_dofile(dofile_path)
                    results[f"Student - {dofile}"] = "PASS" if success else "FAIL"
        
        # Test each parent do-file
        parent_dofiles_dir = os.path.join(self.root_dir, "2_code", "PS_Parents")
        if os.path.exists(parent_dofiles_dir):
            for dofile in sorted(os.listdir(parent_dofiles_dir)):
                if dofile.endswith(".do") and not dofile.startswith("_"):
                    dofile_path = os.path.join(parent_dofiles_dir, dofile)
                    success, _ = self.test_individual_dofile(dofile_path)
                    results[f"Parent - {dofile}"] = "PASS" if success else "FAIL"
        
        # Test the full pipeline
        self.logger.info("-" * 80)
        self.logger.info("TESTING FULL PIPELINE")
        self.logger.info("-" * 80)
        success, output = self.test_full_pipeline()
        results["Full Pipeline"] = "PASS" if success else "FAIL"
        
        # Generate summary report
        elapsed_time = time.time() - start_time
        self.logger.info("-" * 80)
        self.logger.info(f"TEST SUMMARY (completed in {elapsed_time:.2f} seconds)")
        self.logger.info("-" * 80)
        
        for test_name, result in results.items():
            self.logger.info(f"{test_name:50} : {result}")
        
        # Calculate overall pass/fail
        pass_count = sum(1 for result in results.values() if result == "PASS")
        total_count = len(results)
        pass_percentage = (pass_count / total_count) * 100 if total_count > 0 else 0
        
        self.logger.info("-" * 80)
        self.logger.info(f"OVERALL RESULT: {pass_count}/{total_count} tests passed ({pass_percentage:.1f}%)")
        self.logger.info("-" * 80)
        
        return results

# Example usage
if __name__ == "__main__":
    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description='Run tests for Stata data cleaning pipeline')
    parser.add_argument('--root', help='Path to project root directory')
    parser.add_argument('--stata', help='Path to Stata executable')
    parser.add_argument('--skip-stata', action='store_true', help='Skip Stata tests')
    args = parser.parse_args()
    
    # Use provided root or auto-detect
    if args.root:
        PROJECT_ROOT = os.path.abspath(args.root)
    else:
        # Auto-detect root path
        tester = DataCleaningTester()
        PROJECT_ROOT = tester.root_dir
        print(f"Auto-detected root path: {PROJECT_ROOT}")
    
    # Create tester
    tester = DataCleaningTester(PROJECT_ROOT)
    
    # Override Stata command if provided
    if args.stata:
        tester.stata_cmd = args.stata
        print(f"Using provided Stata command: {args.stata}")
    
    # Run tests
    if args.skip_stata:
        print("Skipping Stata tests (--skip-stata flag set)")
    else:
        tester.run_all_tests()