#!/usr/bin/env python3
"""
run_tests.py - Master script to run all test suites and generate a combined report

This script runs all the testing frameworks for the data cleaning pipeline:
1. General test framework for testing do-files and pipelines
2. Data integrity tests for testing data quality and consistency
3. Edge case tests for checking potential issues in the data cleaning process

Usage:
    python run_tests.py [--root /path/to/project/root]
    
    If --root is not provided, the script will auto-detect the root path
    based on the current username (same logic as in 1_master.do).

Author: Based on UGUR DIKTAS and JELKE CLARYSSE's data cleaning code
Date: March 2025
"""

import os
import sys
import argparse
import subprocess
import pandas as pd
import logging
from datetime import datetime
import time
import re
import glob
import getpass

def determine_root_path():
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

def determine_stata_command():
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

# Set up logging
def setup_logging(root_dir):
    """Configure logging to file and console."""
    log_dir = os.path.join(root_dir, "3_logfiles", "test_logs")
    os.makedirs(log_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(log_dir, f"master_test_run_{timestamp}.log")
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(), timestamp, log_file

def extract_test_results(output_text):
    """Extract test results from log output."""
    results = []
    
    # Look for PASS/FAIL/WARNING pattern in logs
    pattern = r"([\w\s\-]+):\s+(PASS|FAIL|WARNING|PARTIAL|INCONCLUSIVE)"
    
    for match in re.finditer(pattern, output_text):
        test_name = match.group(1).strip()
        result = match.group(2)
        
        # Try to extract notes/details
        notes = ""
        # Look for contextual information about this test (usually follows the result line)
        context_match = re.search(rf"{re.escape(test_name)}[^\n]*\n\s+(.+?)(?:\n\n|\n[A-Z])", output_text, re.DOTALL)
        if context_match:
            notes = context_match.group(1).strip()
        
        results.append({
            "test_category": "Data Integrity",
            "test_name": test_name,
            "result": result,
            "notes": notes
        })
    
    return results

def run_python_test(script_path, root_dir):
    """Run a Python-based test script."""
    logger.info(f"Running Python test: {script_path}")
    try:
        result = subprocess.run(
            [sys.executable, script_path, "--root", root_dir],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logger.error(f"Python test failed with return code {result.returncode}")
            logger.error(f"Error output: {result.stderr}")
            return False, result.stderr, []
        else:
            logger.info(f"Python test completed successfully")
            
            # Try to extract structured test results
            test_results = extract_test_results(result.stdout)
            
            return True, result.stdout, test_results
    except Exception as e:
        logger.error(f"Error running Python test: {str(e)}")
        return False, str(e), []

def run_stata_test(script_path, root_dir):
    """Run a Stata-based test script."""
    logger.info(f"Running Stata test: {script_path}")
    
    # Create a temporary wrapper script that sets the root directory
    temp_script = os.path.join(root_dir, "temp_wrapper.do")
    with open(temp_script, "w") as f:
        f.write(f'global root "{root_dir}"\n')
        f.write(f'do "{script_path}"\n')
    
    try:
        # Get appropriate Stata command for this system
        stata_cmd = determine_stata_command()
        logger.info(f"Using Stata command: {stata_cmd}")
        
        # Check if Stata command includes full path with spaces (Windows)
        if stata_cmd.startswith('"') and stata_cmd.endswith('"'):
            # Remove quotes and split into path and arguments
            cmd_parts = [stata_cmd.strip('"'), "-b", "do", temp_script]
        else:
            cmd_parts = [stata_cmd, "-b", "do", temp_script]
            
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            check=False
        )
        
        # Clean up
        if os.path.exists(temp_script):
            os.remove(temp_script)
        
        if result.returncode != 0:
            logger.error(f"Stata test failed with return code {result.returncode}")
            logger.error(f"Error output: {result.stderr}")
            return False, result.stderr, []
        else:
            logger.info(f"Stata test completed successfully")
            
            # Try to extract structured test results
            test_results = []
            
            # Extract detailed test results from edge_case_tests.do output
            if "edge_case_tests.do" in script_path:
                pattern = r"(\w+[\s\w]*?):\s+(PASS|FAIL|ERROR|WARNING|INCONCLUSIVE)\s*(.+?)(?=\n\n|\Z)"
                for match in re.finditer(pattern, result.stdout, re.DOTALL):
                    test_name = match.group(1).strip()
                    result_val = match.group(2)
                    notes = match.group(3).strip() if match.group(3) else ""
                    
                    test_results.append({
                        "test_category": "Edge Cases",
                        "test_name": test_name,
                        "result": result_val,
                        "notes": notes
                    })
            
            return True, result.stdout, test_results
    except Exception as e:
        logger.error(f"Error running Stata test: {str(e)}")
        # Clean up
        if os.path.exists(temp_script):
            os.remove(temp_script)
        return False, str(e), []

def collect_test_results(root_dir, all_script_results):
    """Collect test results from all sources into a standardized format."""
    logger.info("Collecting all test results")
    
    # Initialize combined results
    combined_results = []
    
    # Process results from each script
    for script_name, result_data in all_script_results.items():
        if "test_results" in result_data and result_data["test_results"]:
            # Add these results to the combined list
            combined_results.extend(result_data["test_results"])
    
    # Find all Excel result files as backup
    result_files = glob.glob(os.path.join(root_dir, "tests", "*.xlsx"))
    result_files += glob.glob(os.path.join(root_dir, "tests", "logs", "*.xlsx"))
    
    # If we find Excel files, try to read them
    if result_files and not combined_results:
        logger.info(f"Found {len(result_files)} Excel result files")
        for file in result_files:
            try:
                df = pd.read_excel(file)
                # Convert DataFrame to list of dicts
                file_results = df.to_dict('records')
                combined_results.extend(file_results)
                logger.info(f"Added {len(file_results)} results from {os.path.basename(file)}")
            except Exception as e:
                logger.error(f"Error reading Excel file {file}: {str(e)}")
    
    return combined_results

def generate_report(results, root_dir, timestamp):
    """Generate a combined HTML report from the test results."""
    logger.info("Generating combined report")
    
    if not results:
        logger.error("No results data available for report generation")
        return None, None
    
    # Create reports directory
    reports_dir = os.path.join(root_dir, "tests", "reports")
    os.makedirs(reports_dir, exist_ok=True)
    
    # Convert to DataFrame for easier processing
    results_df = pd.DataFrame(results)
    
    # Generate summary statistics
    total_tests = len(results_df)
    pass_count = len(results_df[results_df['result'] == 'PASS'])
    fail_count = len(results_df[results_df['result'] == 'FAIL'])
    error_count = len(results_df[results_df['result'] == 'ERROR'])
    warning_count = len(results_df[results_df['result'].isin(['WARNING', 'PARTIAL'])])
    
    pass_rate = (pass_count / total_tests) * 100 if total_tests > 0 else 0
    
    # Generate HTML report
    html_report = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Data Cleaning Test Report - {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            h1, h2 {{ color: #2c3e50; }}
            .summary {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
            .pass {{ color: green; }}
            .fail {{ color: red; }}
            .warning {{ color: orange; }}
            .error {{ color: darkred; }}
            table {{ border-collapse: collapse; width: 100%; margin-top: 20px; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
            tr:nth-child(even) {{ background-color: #f9f9f9; }}
            .category-header {{ background-color: #e9ecef; font-weight: bold; }}
        </style>
    </head>
    <body>
        <h1>Data Cleaning Pipeline Test Report</h1>
        <p>Generated on: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        
        <div class="summary">
            <h2>Summary</h2>
            <p><strong>Total Tests:</strong> {total_tests}</p>
            <p><strong>Passed:</strong> <span class="pass">{pass_count} ({pass_rate:.1f}%)</span></p>
            <p><strong>Failed:</strong> <span class="fail">{fail_count}</span></p>
            <p><strong>Errors:</strong> <span class="error">{error_count}</span></p>
            <p><strong>Warnings:</strong> <span class="warning">{warning_count}</span></p>
        </div>
        
        <h2>Detailed Results</h2>
    """
    
    # Group results by test category for better organization
    grouped_results = results_df.groupby('test_category')
    
    html_report += """
        <table>
            <tr>
                <th>Test Category</th>
                <th>Test Name</th>
                <th>Result</th>
                <th>Notes</th>
            </tr>
    """
    
    for category, group in grouped_results:
        html_report += f"""
            <tr class="category-header">
                <td colspan="4">{category}</td>
            </tr>
        """
        
        for _, row in group.iterrows():
            result_class = {
                'PASS': 'pass',
                'FAIL': 'fail',
                'ERROR': 'error',
                'WARNING': 'warning',
                'PARTIAL': 'warning',
                'INCONCLUSIVE': 'warning'
            }.get(row['result'], '')
            
            notes = row.get('notes', '')
            if pd.isna(notes):
                notes = ''
            
            html_report += f"""
                <tr>
                    <td>{category}</td>
                    <td>{row['test_name']}</td>
                    <td class="{result_class}">{row['result']}</td>
                    <td>{notes}</td>
                </tr>
            """
    
    html_report += """
        </table>
    </body>
    </html>
    """
    
    # Write HTML report to file
    report_file = os.path.join(reports_dir, f"test_report_{timestamp}.html")
    with open(report_file, 'w') as f:
        f.write(html_report)
    
    logger.info(f"Report generated: {report_file}")
    
    # Also save combined results to Excel
    excel_file = os.path.join(reports_dir, f"combined_results_{timestamp}.xlsx")
    results_df.to_excel(excel_file, index=False)
    logger.info(f"Combined results saved to Excel: {excel_file}")
    
    return report_file, excel_file

def is_stata_available(stata_cmd):
    """Check if Stata is available with the given command."""
    try:
        # For full path to executable
        if os.path.exists(stata_cmd):
            cmd_parts = [stata_cmd, "-e", "display 1"]
        # For Windows path with spaces
        elif stata_cmd.startswith('"') and stata_cmd.endswith('"'):
            cmd_parts = [stata_cmd.strip('"'), "-e", "display 1"]
        # For command without path
        else:
            cmd_parts = [stata_cmd, "-e", "display 1"]
            
        result = subprocess.run(
            cmd_parts,
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            timeout=5  # 5 second timeout
        )
        return result.returncode == 0
    except (subprocess.SubprocessError, FileNotFoundError, OSError) as e:
        logger.warning(f"Error checking Stata availability: {str(e)}")
        return False

def run_all_tests(root_dir):
    """Run all test suites."""
    logger.info(f"Running all tests from project root: {root_dir}")
    
    # Define which tests to run
    should_skip_stata = globals().get('skip_stata', False)
    
    # Check if Stata is available (if not skipping)
    stata_available = False
    if not should_skip_stata:
        stata_cmd = globals().get('stata_cmd', determine_stata_command())
        stata_available = is_stata_available(stata_cmd)
        if not stata_available:
            logger.warning(f"Stata not found or not working with command: {stata_cmd}")
            logger.warning("Stata tests will be skipped. Use --stata argument to specify Stata path.")
        else:
            logger.info(f"Stata detected and working with command: {stata_cmd}")
    
    # Define the test scripts to run
    test_scripts = [
        {"path": os.path.join(os.path.dirname(__file__), "test_framework.py"), "type": "python"},
        {"path": os.path.join(os.path.dirname(__file__), "data_integrity_tests.py"), "type": "python"}
    ]
    
    # Only add Stata tests if Stata is available and not skipped
    if stata_available and not should_skip_stata:
        test_scripts.append({"path": os.path.join(os.path.dirname(__file__), "edge_case_tests.do"), "type": "stata"})
    
    # Run each test script
    results = {}
    
    for script in test_scripts:
        script_path = script["path"]
        script_type = script["type"]
        script_name = os.path.basename(script_path)
        
        # Check if script exists
        if not os.path.exists(script_path):
            logger.warning(f"Script not found: {script_path}")
            results[script_name] = {
                "success": False,
                "output": "Script not found",
                "test_results": []
            }
            continue
        
        logger.info(f"Running {script_type} script: {script_name}")
        start_time = time.time()
        
        if script_type == "python":
            success, output, test_results = run_python_test(script_path, root_dir)
        else:  # stata
            success, output, test_results = run_stata_test(script_path, root_dir)
        
        elapsed_time = time.time() - start_time
        logger.info(f"Completed in {elapsed_time:.2f} seconds with {'success' if success else 'failure'}")
        
        results[script_name] = {
            "success": success,
            "output": output,
            "elapsed_time": elapsed_time,
            "test_results": test_results
        }
        
        # Log test results summary
        logger.info(f"Extracted {len(test_results)} test results from {script_name}")
    
    # Collect and combine all test results
    all_results = collect_test_results(root_dir, results)
    
    # Generate report
    if all_results:
        report_file, excel_file = generate_report(all_results, root_dir, timestamp)
        logger.info(f"Full test suite completed. Report at: {report_file}")
        logger.info(f"Combined results at: {excel_file}")
    else:
        logger.warning("Unable to generate report due to missing result data")
    
    # Return results
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run all test suites for data cleaning pipeline')
    parser.add_argument('--root', required=False, help='Path to project root directory')
    parser.add_argument('--tests', required=False, help='Comma-separated list of specific test categories to run (default: all)')
    parser.add_argument('--stata', required=False, help='Path to Stata executable (e.g., stata-mp, stata-se, or full path)')
    parser.add_argument('--skip-stata', action='store_true', help='Skip Stata tests entirely')
    parser.add_argument('--python-only', action='store_true', help='Run only Python tests')
    
    args = parser.parse_args()
    
    # Use provided root or auto-detect
    if args.root:
        root_dir = os.path.abspath(args.root)
    else:
        root_dir = determine_root_path()
        print(f"Auto-detected root path: {root_dir}")
    
    # Check if directory exists
    if not os.path.isdir(root_dir):
        print(f"Error: Directory not found: {root_dir}")
        sys.exit(1)
    
    # Set up logging
    logger, timestamp, log_file = setup_logging(root_dir)
    
    # Create tests directory structure if it doesn't exist
    tests_dir = os.path.join(root_dir, "tests")
    os.makedirs(tests_dir, exist_ok=True)
    
    # Configure Stata
    if args.skip_stata or args.python_only:
        logger.info("Stata tests will be skipped (--skip-stata or --python-only flag set)")
        skip_stata = True
    else:
        skip_stata = False
        # Check for Stata on the system
        stata_cmd = args.stata if args.stata else determine_stata_command()
        logger.info(f"Using Stata command: {stata_cmd}")
        
        # Make stata_cmd available to all functions
        globals()['stata_cmd'] = stata_cmd
    
    # Start and time the test suite
    start_time = time.time()
    logger.info(f"Starting test suite run at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Run all tests
    results = run_all_tests(root_dir)
    
    # Calculate and log total time
    total_time = time.time() - start_time
    logger.info(f"Test suite completed in {total_time:.2f} seconds")
    
    # Run all tests
    results = run_all_tests(root_dir)
    
    # Calculate and log total time
    total_time = time.time() - start_time
    logger.info(f"Test suite completed in {total_time:.2f} seconds")
    
    # Print summary to console
    print("\n" + "="*80)
    print(f"TEST SUITE COMPLETE - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total runtime: {total_time:.2f} seconds")
    print(f"Log file: {log_file}")
    
    # Check each script result
    success_count = sum(1 for result in results.values() if result["success"])
    print(f"Scripts: {success_count}/{len(results)} completed successfully")
    
    # Count total test results
    total_test_results = sum(len(result["test_results"]) for result in results.values())
    
    # Count passing tests
    passing_tests = sum(
        sum(1 for tr in result["test_results"] if tr["result"] == "PASS")
        for result in results.values()
    )
    
    if total_test_results > 0:
        pass_percent = (passing_tests / total_test_results) * 100
        print(f"Tests: {passing_tests}/{total_test_results} passed ({pass_percent:.1f}%)")
    
    for script_name, result in results.items():
        status = "SUCCESS" if result["success"] else "FAILURE"
        time_str = f"{result['elapsed_time']:.2f}s" if "elapsed_time" in result else "N/A"
        test_count = len(result["test_results"])
        print(f"  - {script_name}: {status} ({time_str}) - {test_count} tests")
    
    print("="*80)