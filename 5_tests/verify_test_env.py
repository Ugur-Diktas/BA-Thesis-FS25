#!/usr/bin/env python3
"""
Test Environment Verification Script

This script verifies that your test environment is correctly set up before running
the actual tests. It checks:
1. Path structure
2. Stata availability
3. Required Python packages
4. Access to do-files

Usage:
    python verify_test_env.py

"""
import os
import sys
import subprocess
import platform
import tempfile
import shutil
from pathlib import Path


def check_stata():
    """Check if Stata is available in the system path"""
    print("Checking Stata availability...")
    
    # Different commands to try based on OS
    stata_commands = ["stata", "stata-mp", "stata-se", "statamp", "statase"]
    
    # On macOS, check Applications folder
    if platform.system() == "Darwin":  # macOS
        mac_paths = [
            "/Applications/Stata/StataBE.app/Contents/MacOS/stataBE",
            "/Applications/Stata/StataSE.app/Contents/MacOS/stataSE",
            "/Applications/Stata/StataMP.app/Contents/MacOS/stataMP",
            "/Applications/Stata/Stata.app/Contents/MacOS/stata"
        ]
        for path in mac_paths:
            if os.path.exists(path):
                print(f"✅ Found Stata at: {path}")
                return True, path
    
    # On Windows, check Program Files
    elif platform.system() == "Windows":
        win_paths = [
            r"C:\Program Files\Stata18\StataSE-64.exe",
            r"C:\Program Files\Stata18\StataMP-64.exe",
            r"C:\Program Files\Stata18\Stata-64.exe",
            r"C:\Program Files\Stata17\StataSE-64.exe",
        ]
        for path in win_paths:
            if os.path.exists(path):
                print(f"✅ Found Stata at: {path}")
                return True, path
    
    # Try commands in PATH
    for cmd in stata_commands:
        try:
            proc = subprocess.run(["which", cmd] if platform.system() != "Windows" else ["where", cmd], 
                                  capture_output=True, text=True)
            if proc.returncode == 0:
                path = proc.stdout.strip()
                print(f"✅ Found Stata command: {cmd} at {path}")
                return True, cmd
        except Exception:
            pass
    
    print("❌ Stata not found. Please ensure Stata is installed and in your PATH.")
    return False, None


def check_python_packages():
    """Check for required Python packages"""
    print("\nChecking required Python packages...")
    
    required_packages = {
        "pytest": "For test framework",
        "pandas": "For data manipulation",
        "numpy": "For numerical operations",
        "matplotlib": "For plotting",
        "pyreadstat": "For reading/writing SPSS files",
    }
    
    all_found = True
    for package, purpose in required_packages.items():
        try:
            __import__(package)
            print(f"✅ {package}: Found ({purpose})")
        except ImportError:
            print(f"❌ {package}: Missing! ({purpose})")
            all_found = False
    
    if not all_found:
        print("\nPlease install missing packages with:")
        print("pip install pytest pandas numpy matplotlib pyreadstat")
    
    return all_found


def check_project_structure():
    """Verify the project structure"""
    print("\nChecking project structure...")
    
    # Try to find project root based on common folders
    potential_roots = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..")),  # One level up
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")),  # Two levels up
    ]
    
    # Also check if we're in a git repository
    try:
        git_root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], 
            capture_output=True, text=True, check=False
        ).stdout.strip()
        if git_root:
            potential_roots.insert(0, git_root)
    except Exception:
        pass
    
    for root in potential_roots:
        # Check for essential directories
        expected_dirs = [
            "2_code",
            "2_code/PS_Parents",
            "2_code/PS_Students",
            "5_tests"
        ]
        
        missing_dirs = []
        for directory in expected_dirs:
            full_path = os.path.join(root, directory)
            if not os.path.isdir(full_path):
                missing_dirs.append(directory)
        
        if not missing_dirs:
            print(f"✅ Found valid project root: {root}")
            
            # Check for specific do-files
            dofile_path = os.path.join(root, "2_code", "PS_Parents", "1_ps_parents_anonymize.do")
            if os.path.exists(dofile_path):
                print(f"✅ Found target do-file: {dofile_path}")
            else:
                print(f"❌ Missing target do-file: {dofile_path}")
                return False, root
                
            return True, root
    
    print("❌ Could not find a valid project structure.")
    print("Please run this script from within the project directory.")
    return False, None


def check_project_files(project_root):
    """Check that required files exist and have expected content"""
    print("\nChecking project files...")
    
    # Check globals.do
    globals_path = os.path.join(project_root, "2_code", "2_globals.do")
    if not os.path.exists(globals_path):
        print(f"❌ globals.do not found at {globals_path}")
        return False
    
    with open(globals_path, 'r', encoding='utf-8') as f:
        globals_content = f.read()
        
        # Check for key phrases that should be in the globals file
        key_phrases = [
            "raw_data",
            "processed_data",
            "global"
        ]
        
        missing_phrases = []
        for phrase in key_phrases:
            if phrase not in globals_content:
                missing_phrases.append(phrase)
        
        if missing_phrases:
            print(f"❌ globals.do missing expected content: {', '.join(missing_phrases)}")
            return False
        else:
            print(f"✅ globals.do looks valid")
    
    # Check anonymize do-file
    dofile_path = os.path.join(project_root, "2_code", "PS_Parents", "1_ps_parents_anonymize.do")
    with open(dofile_path, 'r', encoding='utf-8') as f:
        dofile_content = f.read()
        
        # Check for key phrases that should be in the anonymize file
        key_phrases = [
            "ps_parents_anonymize",
            "drop if",
            "save"
        ]
        
        missing_phrases = []
        for phrase in key_phrases:
            if phrase not in dofile_content:
                missing_phrases.append(phrase)
        
        if missing_phrases:
            print(f"❌ anonymize.do missing expected content: {', '.join(missing_phrases)}")
            return False
        else:
            print(f"✅ anonymize.do looks valid")
    
    return True


def run_simple_stata_test(stata_cmd):
    """Run a simple Stata command to verify it works"""
    print("\nRunning a simple Stata test...")
    
    # Create a simple do-file
    with tempfile.NamedTemporaryFile(suffix='.do', mode='w', delete=False) as f:
        temp_dofile = f.name
        f.write("""
        clear all
        set more off
        display "Hello from Stata!"
        display c(stata_version)
        exit
        """)
    
    try:
        # Format command based on OS and Stata path
        if stata_cmd.startswith('"') and stata_cmd.endswith('"'):
            # For Windows with spaces in path
            cmd = [stata_cmd.strip('"'), "-b", "do", temp_dofile]
        else:
            # For macOS/Linux
            cmd = [stata_cmd, "-b", "do", temp_dofile]
        
        print(f"Running command: {' '.join(cmd)}")
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Stata test successful!")
            return True
        else:
            print("❌ Stata test failed!")
            print("\nSTDOUT:")
            print(result.stdout)
            print("\nSTDERR:")
            print(result.stderr)
            return False
    finally:
        if os.path.exists(temp_dofile):
            os.remove(temp_dofile)


def main():
    """Main function to run all checks"""
    print("=" * 60)
    print("TEST ENVIRONMENT VERIFICATION")
    print("=" * 60)
    
    # Check project structure
    structure_ok, project_root = check_project_structure()
    if not structure_ok:
        return False
    
    # Check Stata availability
    stata_ok, stata_cmd = check_stata()
    if not stata_ok:
        return False
    
    # Check Python packages
    packages_ok = check_python_packages()
    if not packages_ok:
        return False
    
    # Check project files (globals.do and anonymize.do)
    files_ok = check_project_files(project_root)
    if not files_ok:
        return False
    
    # Run simple Stata test
    stata_test_ok = run_simple_stata_test(stata_cmd)
    if not stata_test_ok:
        return False
    
    print("\n" + "=" * 60)
    print("✅ ALL CHECKS PASSED!")
    print("Your test environment appears to be correctly set up.")
    print("\nTo run your tests with the globals.do setup, use:")
    print(f"  pytest {os.path.join(project_root, '5_tests/Tests_Parents/1_test_parents_anonymize.py')} -v")
    print("\nThe test now accounts for your project structure where globals are defined")
    print("in 2_globals.do and will create a temporary test environment with the proper setup.")
    print("=" * 60)
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)