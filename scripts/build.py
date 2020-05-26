"""
This script automatically generates the 'cui.modinfo' based on the mod files.
It relies heavily on how mod files are organized.
"""

from datetime import date
from pathlib import Path
from xml.dom.minidom import parseString
from xml.etree import ElementTree
from xml.etree.ElementTree import Element, SubElement

# Version
GAME_VERSION = '1.0.1.501 (504666)'
MOD_VERSION = '1.5.2'

# Paths
PATH_PROJECT = Path(__file__).parents[1]
PATH_MOD     = Path(PATH_PROJECT, 'mod')
PATH_MODINFO = Path(PATH_MOD, 'cui.modinfo')

# Mod Information
MOD_ID      = '5f504949-398a-4038-a838-43c3acc4dc10'
MOD_NAME    = '[COLOR_Civ6LightBlue]Concise UI[ENDCOLOR]'
MOD_TEASER  = 'For a better gaming experience.'
MOD_DESC    = (
    'Concise UI greatly improves the game experience by '
    'modifying the vanilla UI and adding new UI elements to the game.'
    f'[NEWLINE][NEWLINE]Game Version: {GAME_VERSION}'
)
MOD_AUTHOR  = 'eudaimonia'
MOD_SAVED   = '0'
MOD_COMPT   = '2.0'
CRITERIA_1  = 'Expansion1AndBeyond'
RULE_SET_1  = 'RULESET_EXPANSION_1,RULESET_EXPANSION_2'
CRITERIA_2  = 'Expansion2AndBeyond'
RULE_SET_2  = 'RULESET_EXPANSION_2'


def build():
    update_version_info()
    modinfo = _modinfo()
    try:
        _save(modinfo)
    except Exception as e:
        err_name = type(e).__name__
        print(f'[×] build failed\n    > {err_name}: {e.args}')
    else:
        print('[√] build complete')


def update_version_info():
    update_file = Path(PATH_MOD, 'lib/cui_update.lua')
    lines = []
    with open(update_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    lines[0] = f'CuiVersion = "{MOD_VERSION}"\n'
    lines[1] = f'LastUpdate = "{date.today()}"\n'
    with open(update_file, 'w', encoding='utf-8') as f:
        f.writelines(lines)


def _modinfo():
    root = Element('Mod', id=MOD_ID, version=MOD_VERSION)
    _add_properties(root)
    _add_criteria(root)
    _add_frontend(root)
    _add_ingame(root)
    _add_files(root)
    str_xml = ElementTree.tostring(root, encoding='utf-8')
    obj_dom = parseString(str_xml.decode('utf-8'))
    modinfo = obj_dom.toprettyxml(indent='  ', encoding='utf-8')
    return modinfo


def _save(modinfo):
    with open(PATH_MODINFO, 'w+', encoding='utf-8') as f:
        f.write(modinfo.decode('utf-8'))


# sub elements #################################################################


def _add_properties(root):
    properties = SubElement(root, 'Properties')
    SubElement(properties, 'Name')              .text = MOD_NAME
    SubElement(properties, 'Teaser')            .text = MOD_TEASER
    SubElement(properties, 'Description')       .text = MOD_DESC
    SubElement(properties, 'Authors')           .text = MOD_AUTHOR
    SubElement(properties, 'AffectsSavedGames') .text = MOD_SAVED
    SubElement(properties, 'CompatibleVersions').text = MOD_COMPT


def _add_criteria(root):
    criteria = SubElement(root, 'ActionCriteria')
    expansion_1 = SubElement(criteria, 'Criteria', id=CRITERIA_1, any='1')
    SubElement(expansion_1, 'RuleSetInUse').text = RULE_SET_1
    expansion_2 = SubElement(criteria, 'Criteria', id=CRITERIA_2, any='1')
    SubElement(expansion_2, 'RuleSetInUse').text = RULE_SET_2


def _add_frontend(root):
    frontend = SubElement(root, 'FrontEndActions')

    # text
    fe_text = SubElement(frontend, 'UpdateText', id='Cui_Front_End_Text')
    _sub_files(sub=fe_text, key='config', suffix='.sql')

    # database
    fe_data = SubElement(frontend, 'UpdateDatabase',
                         id='Cui_Front_End_Database')
    _sub_files(sub=fe_data, key='config', suffix='.xml')


def _add_ingame(root):
    ingame = SubElement(root, 'InGameActions')

    # assets
    asset = SubElement(ingame, 'ImportFiles', id='Cui_Assets')
    _sub_files(sub=asset, key='assets', suffix=None)

    # localization
    update = SubElement(ingame, 'UpdateText', id='Cui_Text')
    _sub_files(sub=update, key='config', suffix='.sql')
    _sub_files(sub=update, key='localization', suffix=None)

    # lib
    lib = SubElement(ingame, 'ImportFiles', id='Cui_Lib')
    lib_p = SubElement(lib, 'Properties')
    SubElement(lib_p, 'LoadOrder').text = '10'
    _sub_files(sub=lib, key='lib', suffix=None)

    # support
    support = SubElement(ingame, 'ImportFiles', id='Cui_Support')
    support_p = SubElement(support, 'Properties')
    SubElement(support_p, 'LoadOrder').text = '11'
    _sub_files(sub=support, key='support', suffix=None)

    # base game
    base = SubElement(ingame, 'ImportFiles', id='Cui_Base')
    base_p = SubElement(base, 'Properties')
    SubElement(base_p, 'LoadOrder').text = '12'
    _sub_files(sub=base, key='base', suffix=None)

    # expansion1
    expansion1 = SubElement(ingame, 'ImportFiles',
                            id='Cui_Expansion1', criteria=CRITERIA_1)
    expansion1_p = SubElement(expansion1, 'Properties')
    SubElement(expansion1_p, 'LoadOrder').text = '13'
    _sub_files(sub=expansion1, key='expansion1', suffix=None)

    # expansion2
    expansion2 = SubElement(ingame, 'ImportFiles',
                            id='Cui_Expansion2', criteria=CRITERIA_2)
    expansion2_p = SubElement(expansion2, 'Properties')
    SubElement(expansion2_p, 'LoadOrder').text = '14'
    _sub_files(sub=expansion2, key='expansion2', suffix=None)

    # additions - import files
    add_if = SubElement(ingame, 'ImportFiles', id='Cui_Additions')
    add_if_p = SubElement(add_if, 'Properties')
    SubElement(add_if_p, 'LoadOrder').text = '15'
    _sub_files(sub=add_if, key='additions', suffix=None)

    # additions - add user interface
    add_ui = SubElement(ingame, 'AddUserInterfaces', id='Cui_UI')
    add_ui_p = SubElement(add_ui, 'Properties')
    SubElement(add_ui_p, 'Context').text = 'InGame'
    _sub_files(sub=add_ui, key='additions', suffix='.xml')


def _add_files(root):
    files = SubElement(root, 'Files')
    _sub_files(sub=files, key=None, suffix=None)


# help functions ###############################################################


def _get_files(mod_path, key, suffix):
    for item in mod_path.iterdir():
        if item.suffix == '.modinfo':
            continue
        if item.is_file():
            right_key = key is None or item.parents[0].name == key
            right_suf = suffix is None or item.suffix == suffix
            if right_key and right_suf:
                yield item
        elif item.is_dir():
            yield from _get_files(item, key, suffix)


def _sub_files(*, sub, key, suffix):
    for f in _get_files(PATH_MOD, key, suffix):
        SubElement(sub, 'File').text = _relative_path(f)


def _relative_path(full_path):
    str_path = str(full_path).replace('\\', '/')
    rel_path = str_path.split('mod/', 1)[1]
    return rel_path


if __name__ == '__main__':
    build()
