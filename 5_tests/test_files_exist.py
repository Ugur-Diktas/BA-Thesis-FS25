import os
import pytest
from conftest import project_root

def test_essential_files_exist(project_root):
    """
    Überprüft, dass alle essenziellen Code-Dateien existieren.
    """
    essential_files = [
        os.path.join(project_root, "2_code", "1_master.do"),
        os.path.join(project_root, "2_code", "2_globals.do"),
    ]
    for file_path in essential_files:
        assert os.path.exists(file_path), f"Essenzielle Datei nicht gefunden: {file_path}"

def test_essential_directories_exist(project_root):
    """
    Überprüft, dass alle wesentlichen Ordner (raw data, processed data, Code-Unterordner, Logfiles) vorhanden sind.
    """
    essential_dirs = [
        os.path.join(project_root, "1_data", "raw"),
        os.path.join(project_root, "1_data", "processed"),
        os.path.join(project_root, "2_code", "PS_Students"),
        os.path.join(project_root, "2_code", "PS_Parents"),
        os.path.join(project_root, "3_logfiles"),
    ]
    for dir_path in essential_dirs:
        assert os.path.exists(dir_path), f"Essentieller Ordner nicht gefunden: {dir_path}"
