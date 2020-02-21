"""
This script copies the mod from the project folder
to the steam directory for testing purposes.
"""

from pathlib import Path
import shutil
from build import build


# Paths
PATH_PROJECT = Path(__file__).parents[1]
PATH_MOD     = Path(PATH_PROJECT, 'mod')
# ! This is the path on my computer, if you want to try this script,
#   please change it to where you installed the steam.
PATH_STEAM   = Path(r'e:\Steam\steamapps\workshop\content\289070\1671978687')


def copy_():
    try:
        shutil.copytree(PATH_MOD, PATH_STEAM, dirs_exist_ok=True)  # python 3.8+
    except Exception as e:
        err_name = type(e).__name__
        print(f'[×] copy failed\n    > {err_name}: {e.args}')
    else:
        print('[√] copy complete')


if __name__ == "__main__":
    build()
    copy_()
