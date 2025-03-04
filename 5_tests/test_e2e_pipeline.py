import os
import shutil
import subprocess
import tempfile
import pandas as pd
import pytest

from conftest import project_root, stata_command, create_sample_dataset

def setup_temp_environment(root):
    """
    Creates a temporary test environment with the required folder structure.
    Returns a dictionary with key paths.
    """
    temp_env = tempfile.mkdtemp(prefix="test_pipeline_")
    # Create 1_data directories
    raw_dir = os.path.join(temp_env, "1_data", "raw")
    processed_dir = os.path.join(temp_env, "1_data", "processed")
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(processed_dir, exist_ok=True)
    # Create subdirectories for processed data
    ps_students_dir = os.path.join(processed_dir, "PS_Students")
    ps_parents_dir = os.path.join(processed_dir, "PS_Parents")
    os.makedirs(ps_students_dir, exist_ok=True)
    os.makedirs(ps_parents_dir, exist_ok=True)
    # Create code and log directories
    code_dir = os.path.join(temp_env, "2_code")
    log_dir = os.path.join(temp_env, "3_logfiles")
    os.makedirs(code_dir, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)
    return {
        "root": temp_env,
        "raw": raw_dir,
        "processed": processed_dir,
        "ps_students": ps_students_dir,
        "ps_parents": ps_parents_dir,
        "code": code_dir,
        "logs": log_dir
    }

def write_minimal_master(env):
    """
    Writes a minimal master.do file into the temporary environment.
    This do-file sets globals using absolute paths and writes the log file directly
    to the "3_logfiles" folder.
    """
    master_content = f"""
clear all
set more off

global root "{env['root']}"
global raw_data "{env['raw']}"
global processed_data "{env['processed']}"

cap log close
log using "{env['logs']}/test_master.log", replace

* Process Students Data:
use "{env['raw']}/PoF_PS_Students.dta", clear
save "{env['processed']}/PS_Students/ps_stu_final.dta", replace

* Process Parents Data:
use "{env['raw']}/PoF_PS_Parents.dta", clear
save "{env['processed']}/PS_Parents/ps_parents_final.dta", replace

display "E2E_TEST_SUCCESS: Output files created"
log close
exit
"""
    master_path = os.path.join(env["code"], "1_master.do")
    with open(master_path, "w", encoding="utf-8") as f:
        f.write(master_content)
    return master_path

def create_input_datasets(env, create_sample_dataset):
    """
    Creates minimal sample datasets for students and parents in the raw folder.
    """
    students_input = os.path.join(env["raw"], "PoF_PS_Students.dta")
    parents_input = os.path.join(env["raw"], "PoF_PS_Parents.dta")
    create_sample_dataset("students", students_input, num_records=10)
    create_sample_dataset("parents", parents_input, num_records=10)
    return students_input, parents_input

def run_pipeline(master_path, env, stata_cmd):
    """
    Runs the provided master.do file using Stata in the temporary environment.
    """
    cmd = [stata_cmd, "-b", "do", master_path]
    result = subprocess.run(cmd, cwd=env["root"], capture_output=True, text=True)
    return result

def check_output_files(env):
    """
    Checks whether the expected output files exist.
    """
    student_output = os.path.join(env["processed"], "PS_Students", "ps_stu_final.dta")
    parent_output = os.path.join(env["processed"], "PS_Parents", "ps_parents_final.dta")
    return os.path.exists(student_output) and os.path.exists(parent_output)

@pytest.fixture
def temp_test_env(project_root):
    """
    Creates a temporary test environment and returns a dictionary with key paths.
    Cleans up after the test.
    """
    env = setup_temp_environment(project_root)
    yield env
    shutil.rmtree(env["root"])

def test_e2e_pipeline(temp_test_env, project_root, stata_command, create_sample_dataset):
    """
    End-to-End Test:
      1. Sets up a temporary test environment.
      2. Creates minimal raw input datasets.
      3. Writes a minimal master.do file that processes the input.
      4. Runs the master.do file via Stata.
      5. Verifies that the log file contains the success message and the expected output files exist.
    """
    env = temp_test_env

    # Create raw input datasets.
    create_input_datasets(env, create_sample_dataset)

    # Write the minimal master.do file.
    master_path = write_minimal_master(env)

    # Run the master.do file.
    result = run_pipeline(master_path, env, stata_command)
    print("\n--- STATA STDOUT ---")
    print(result.stdout)
    print("\n--- STATA STDERR ---")
    print(result.stderr)
    assert result.returncode == 0, f"Stata command failed: {result.stderr}"

    # Check the log file exists in the log directory.
    log_file = os.path.join(env["logs"], "test_master.log")
    assert os.path.exists(log_file), "Log file was not created."

    # Read the log file to check for the success message.
    with open(log_file, "r", encoding="utf-8") as f:
        log_content = f.read()
    assert "E2E_TEST_SUCCESS" in log_content, "Master did not report success in the log file."

    # Verify that the output files exist.
    assert check_output_files(env), "Expected output files were not created."
