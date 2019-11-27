import os, shutil, errno
from build import build

MOD_PATH = os.path.dirname(os.path.abspath(__file__)) + '\\mod'
DIST = 'E:\\Steam\\steamapps\\workshop\\content\\289070\\1671978687'


def remove_copy(src, dst):
    print('Trying to copy mod to steam folder...')
    try:
        if os.path.exists(dst):
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print('Copy success.')
    except PermissionError:
        print('PermissionError')
        pass
    except NotADirectoryError:
        print('NotADirectoryError')
        pass
    except OSError as e:
        ignorable = (
            e.errno in (errno.ENOTDIR, errno.EACCES, errno.ENOENT)
            # or -> getattr(e, "winerror", None) == 267
        )
        if ignorable:
            print('Error')
        else:
            raise


if __name__ == "__main__":
    if build():
        remove_copy(MOD_PATH, DIST)
