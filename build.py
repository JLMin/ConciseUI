import os
from xml.etree import ElementTree
from xml.etree.ElementTree import Element, SubElement, Comment
from xml.dom import minidom
from datetime import date

# Pathes
MOD_PATH = os.path.dirname(os.path.abspath(__file__)) + '\\mod\\'
MODINFO_PATH = MOD_PATH + 'cui.modinfo'

# Mod Information
MOD_ID      = '5f504949-398a-4038-a838-43c3acc4dc10'
MOD_VERSION = '1.3'
MOD_NAME    = '[COLOR_Civ6LightBlue]Concise UI[ENDCOLOR]'
MOD_TEASER  = 'For a better gaming experience.'
MOD_DESC    = 'Concise UI greatly improves the game experience by '\
              'modifying the vanilla UI and adding new UI elements to the game.'\
              '[NEWLINE][NEWLINE]Game Version: 1.0.0.328 (426563)'
MOD_AUTHOR  = 'eudaimonia'
MOD_SAVED   = '0'
MOD_COMPT   = '2.0'
CRITERIA_1  = 'Expansion1AndBeyond'
RULE_SET_1  = 'RULESET_EXPANSION_1,RULESET_EXPANSION_2'
CRITERIA_2  = 'Expansion2AndBeyond'
RULE_SET_2  = 'RULESET_EXPANSION_2'


def __build_modinfo():
    mod_files = __load_files()

    # Mod
    root = Element('Mod', id=MOD_ID, version=MOD_VERSION)

    # Properties
    properties = SubElement(root, 'Properties')
    SubElement(properties, 'Name')              .text = MOD_NAME
    SubElement(properties, 'Teaser')            .text = MOD_TEASER
    SubElement(properties, 'Description')       .text = MOD_DESC
    SubElement(properties, 'Authors')           .text = MOD_AUTHOR
    SubElement(properties, 'AffectsSavedGames') .text = MOD_SAVED
    SubElement(properties, 'CompatibleVersions').text = MOD_COMPT

    # ActionCriteria
    criteria = SubElement(root, 'ActionCriteria')
    # Expansion 1
    exp_1 = SubElement(criteria, 'Criteria', id=CRITERIA_1, any='1')
    SubElement(exp_1, 'RuleSetInUse').text = RULE_SET_1
    # Expansion 2
    exp_2 = SubElement(criteria, 'Criteria', id=CRITERIA_2, any='1')
    SubElement(exp_2, 'RuleSetInUse').text = RULE_SET_2

    # FrontEndActions
    if 'config' in mod_files:
        frontend = SubElement(root, 'FrontEndActions')
        fe_text = SubElement(frontend, 'UpdateText', id='Cui_Front_End_Text')
        fe_database = SubElement(frontend, 'UpdateDatabase', id='Cui_Front_End_Database')
        for f in mod_files['config']:
            if f.endswith('sql'):
                SubElement(fe_text, 'File').text = f
            elif f.endswith('xml'):
                SubElement(fe_database, 'File').text = f

    # InGameActions
    ingame = SubElement(root, 'InGameActions')
    # ast
    if 'assets' in mod_files:
        asset = SubElement(ingame, 'ImportFiles', id='Cui_Assets')
        for f in mod_files['assets']:
            SubElement(asset, 'File').text = f
    # loc
    if 'localization' in mod_files:
        update = SubElement(ingame, 'UpdateText', id='Cui_Text')
        for f in mod_files['localization']:
            SubElement(update, 'File').text = f
    # lib
    if 'lib' in mod_files:
        lib = SubElement(ingame, 'ImportFiles', id='Cui_Lib')
        lib_p = SubElement(lib, 'Properties')
        SubElement(lib_p, 'LoadOrder').text = '10'
        for f in mod_files['lib']:
            SubElement(lib, 'File').text = f
    # mod support
    if 'support' in mod_files:
        support = SubElement(ingame, 'ImportFiles', id='Cui_Support')
        support_p = SubElement(support, 'Properties')
        SubElement(support_p, 'LoadOrder').text = '11'
        for f in mod_files['support']:
            SubElement(support, 'File').text = f
    # mod base
    if 'base' in mod_files:
        base = SubElement(ingame, 'ImportFiles', id='Cui_Base')
        base_p = SubElement(base, 'Properties')
        SubElement(base_p, 'LoadOrder').text = '12'
        for f in mod_files['base']:
            SubElement(base, 'File').text = f
    # mod expansion1
    if 'expansion1' in mod_files:
        expansion1 = SubElement(ingame, 'ImportFiles', id='Cui_Expansion1', criteria=CRITERIA_1)
        expansion1_p = SubElement(expansion1, 'Properties')
        SubElement(expansion1_p, 'LoadOrder').text = '13'
        for f in mod_files['expansion1']:
            SubElement(expansion1, 'File').text = f
    # mod expansion2
    if 'expansion2' in mod_files:
        expansion2 = SubElement(ingame, 'ImportFiles', id='Cui_Expansion2', criteria=CRITERIA_2)
        expansion2_p = SubElement(expansion2, 'Properties')
        SubElement(expansion2_p, 'LoadOrder').text = '14'
        for f in mod_files['expansion2']:
            SubElement(expansion2, 'File').text = f
    # additions
    if 'additions' in mod_files:
        # import files
        additions = SubElement(ingame, 'ImportFiles', id='Cui_Additions')
        additions_p = SubElement(additions, 'Properties')
        SubElement(additions_p, 'LoadOrder').text = '15'
        for f in mod_files['additions']:
            SubElement(additions, 'File').text = f
        # add user interface
        add_ui = SubElement(ingame, 'AddUserInterfaces', id='Cui_UI')
        add_ui_p = SubElement(add_ui, 'Properties')
        SubElement(add_ui_p, 'Context').text = 'InGame'
        for f in mod_files['additions']:
            if f.endswith('xml'):
                SubElement(add_ui, 'File').text = f

    # Files
    files = SubElement(root, 'Files')
    for _, fs in mod_files.items():
        for f in fs:
            SubElement(files, 'File').text = f

    return root


def __load_files():
    group = __group_files(MOD_PATH)
    for k, v in group.items():
        group[k] = sorted(list(v))
    return group


def __group_files(path, group=None):
    if group is None:
        group = dict()
    files = os.listdir(path)
    for f in files:
        if f.endswith('modinfo'):
            continue
        full_path = os.path.join(path, f)
        if os.path.isdir(full_path):
            __group_files(full_path, group=group)
        else:
            f_name = path.split('\\')[-1]
            fs = __files_in_path(path)
            if f_name in group:
                group[f_name].update(fs)
            else:
                group[f_name] = __files_in_path(path)
    return group


def __files_in_path(path):
    file_set = set()
    files = os.listdir(path)
    for f in files:
        absolute_path = os.path.join(path, f)
        relative_path = os.path.relpath(absolute_path, MOD_PATH)
        file_set.add(relative_path.replace('\\', '/'))
    return file_set


def __prettify(elem):
    raw_string = ElementTree.tostring(elem, encoding='utf-8')
    xml_string = minidom.parseString(raw_string.decode('utf-8'))
    pty_string = xml_string.toprettyxml(indent='  ', encoding='utf-8')
    return pty_string


def __save_to_file(text):
    with open(MODINFO_PATH, 'w+', encoding='utf-8') as modinfo:
        modinfo.write(text.decode('utf-8'))


def build():
    print('Build modinfo:')
    try:
        print(' - Building...')
        root = __build_modinfo()
        print(' - Prettifing...')
        text = __prettify(root)
        print(' - Saving...')
        __save_to_file(text)
    except Exception as e:
        print('Build faile.')
        raise
        return False
    else:
        print('Build success.')
        return True


# Build
if __name__ == '__main__':
    build()
