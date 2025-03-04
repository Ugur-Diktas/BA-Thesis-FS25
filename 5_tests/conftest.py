import os
import pytest
import subprocess
import tempfile
import pandas as pd
import numpy as np
import getpass
import shutil

def determine_project_root():
    """
    Bestimme das Projektverzeichnis basierend auf dem Benutzernamen oder Umgebungsvariablen.
    """
    username = getpass.getuser()
    user_roots = {
        "jelkeclarysse": "/Users/jelkeclarysse/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning",
        "ugurdiktas": "/Users/ugurdiktas/Library/CloudStorage/OneDrive-UniversitätZürichUZH/3_STUDENTS/13_Cleaning"
    }
    if username in user_roots and os.path.exists(user_roots[username]):
        return user_roots[username]
    if 'DATA_CLEANING_ROOT' in os.environ:
        return os.environ['DATA_CLEANING_ROOT']
    # Fallback: ein Verzeichnis oberhalb dieser Datei
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def find_stata_command():
    """
    Liefert den passenden Stata-Befehl basierend auf dem Benutzernamen oder Standardwerten.
    """
    username = getpass.getuser()
    user_stata = {
        "jelkeclarysse": "stata-mp",
        "ugurdiktas": "/Applications/Stata/StataBE.app/Contents/MacOS/stataBE"
    }
    if username in user_stata:
        return user_stata[username]
    return "stata"  # Fallback

# -----------------------------
# Pytest Fixtures
# -----------------------------

@pytest.fixture(scope="session")
def project_root():
    root = determine_project_root()
    print(f"Using project root: {root}")
    return root

@pytest.fixture(scope="session")
def stata_command():
    cmd = find_stata_command()
    print(f"Using Stata command: {cmd}")
    return cmd

@pytest.fixture(scope="function")
def temp_dir():
    td = tempfile.mkdtemp()
    yield td
    shutil.rmtree(td)

@pytest.fixture
def create_sample_dataset():
    """
    Factory-Funktion zur Erzeugung eines Sample-Datensatzes.
    
    Usage:
        df = create_sample_dataset("students", output_path, num_records=100, with_issues=False)
    """
    def _create_dataset(dataset_type, output_path, num_records=100, with_issues=False):
        np.random.seed(42)
        response_ids = [f"R_{i:08d}" for i in range(1, num_records + 1)]
        common_data = {
            "ResponseId": response_ids,
            "contract": np.random.randint(0, 2, size=num_records),
            "female": np.random.randint(0, 2, size=num_records),
            "StartDate": pd.date_range(start="2024-10-01", periods=num_records)
        }
        if dataset_type.lower() == "students":
            data = {
                **common_data,
                "age": np.random.randint(15, 20, size=num_records),
                "sit": np.random.choice([1, 2, 4], size=num_records),
                "home_sit": np.random.randint(1, 8, size=num_records),
                "math_level": np.random.randint(1, 6, size=num_records),
                "lang_level": np.random.randint(1, 6, size=num_records),
                "belief_fit__1": np.random.randint(1, 6, size=num_records),
                "belief_fit__2": np.random.randint(1, 6, size=num_records),
                "like_task__1": np.random.randint(1, 6, size=num_records),
                "like_task__2": np.random.randint(1, 6, size=num_records),
                "mother_occ": np.random.choice(["Teacher", "Doctor", "Engineer", "Nurse"], size=num_records),
                "father_occ": np.random.choice(["Engineer", "Doctor", "Technician", "Manager"], size=num_records),
                "plan_": np.random.choice(["KV", "Informatiker", "FaGe", "FaBe"], size=num_records)
            }
            if with_issues:
                # Füge fehlende Werte hinzu, indem die Spalte in float konvertiert wird
                missing_indexes = np.random.choice(num_records, size=int(num_records * 0.1), replace=False)
                data["belief_fit__1"] = data["belief_fit__1"].astype(float)
                for idx in missing_indexes:
                    data["belief_fit__1"][idx] = np.nan
        elif dataset_type.lower() == "parents":
            data = {
                **common_data,
                "Parent_type_": np.random.randint(1, 3, size=num_records),
                "home_sit_par": np.random.randint(1, 8, size=num_records),
                "belief_fit_1": np.random.randint(1, 6, size=num_records).astype(float),
                "belief_fit_2": np.random.randint(1, 6, size=num_records).astype(float),
                "like_task_1": np.random.randint(1, 6, size=num_records).astype(float),
                "like_task_2": np.random.randint(1, 6, size=num_records).astype(float),
                "swissborn_1_1": np.random.randint(1, 3, size=num_records),
                "swissborn_1_2": np.random.randint(1, 3, size=num_records)
            }
        else:
            raise ValueError(f"Unknown dataset type: {dataset_type}")
        
        df = pd.DataFrame(data)
        if output_path is not None:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            ext = os.path.splitext(output_path)[1].lower()
            if ext == ".dta":
                df.to_stata(output_path, write_index=False)
            elif ext == ".csv":
                df.to_csv(output_path, index=False)
            elif ext == ".sav":
                try:
                    import pyreadstat
                    pyreadstat.write_sav(df, output_path)
                except ImportError:
                    df.to_csv(output_path, index=False)
            else:
                df.to_csv(output_path, index=False)
        return df

    return _create_dataset
