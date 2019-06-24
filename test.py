import os, shutil, errno
from build import build

MOD_PATH = os.path.dirname(os.path.abspath(__file__)) + '\\mod'
DIST = 'E:\\Steam\\steamapps\\workshop\\content\\289070\\1671978687'


def copy_mod(src, dst):
    try:
        if os.path.exists(dst):
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
    except OSError as exc:
        if exc.errno == errno.ENOTDIR:
            shutil.copy(src, dst)
        else:
            raise


if __name__ == "__main__":
    if build():
        copy_mod(MOD_PATH, DIST)
        print('Copy success.')
