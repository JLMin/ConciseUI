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
MOD_VERSION = '1.4.0'
MOD_NAME    = '[COLOR_Civ6LightBlue]Concise UI[ENDCOLOR]'
MOD_TEASER  = 'For a better gaming experience.'
MOD_DESC    = 'Concise UI greatly improves the game experience by '\
              'modifying the vanilla UI and adding new UI elements to the game.'\
              '[NEWLINE][NEWLINE]Game Version: 1.0.0.341 (443561)'
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
        for file in mod_files['config']:
            if file.endswith('sql'):
                SubElement(fe_text, 'File').text = file
            elif file.endswith('xml'):
                SubElement(fe_database, 'File').text = file

    # InGameActions
    ingame = SubElement(root, 'InGameActions')
    # ast
    if 'assets' in mod_files:
        asset = SubElement(ingame, 'ImportFiles', id='Cui_Assets')
        for file in mod_files['assets']:
            SubElement(asset, 'File').text = file
    # loc
    if 'localization' in mod_files:
        update = SubElement(ingame, 'UpdateText', id='Cui_Text')
        for file in mod_files['config']:
            if file.endswith('sql'):
                SubElement(update, 'File').text = file
        for file in mod_files['localization']:
            SubElement(update, 'File').text = file
    # lib
    if 'lib' in mod_files:
        lib = SubElement(ingame, 'ImportFiles', id='Cui_Lib')
        lib_p = SubElement(lib, 'Properties')
        SubElement(lib_p, 'LoadOrder').text = '10'
        for file in mod_files['lib']:
            SubElement(lib, 'File').text = file
    # mod support
    if 'support' in mod_files:
        support = SubElement(ingame, 'ImportFiles', id='Cui_Support')
        support_p = SubElement(support, 'Properties')
        SubElement(support_p, 'LoadOrder').text = '11'
        for file in mod_files['support']:
            SubElement(support, 'File').text = file
    # mod base
    if 'base' in mod_files:
        base = SubElement(ingame, 'ImportFiles', id='Cui_Base')
        base_p = SubElement(base, 'Properties')
        SubElement(base_p, 'LoadOrder').text = '12'
        for file in mod_files['base']:
            SubElement(base, 'File').text = file
    # mod expansion1
    if 'expansion1' in mod_files:
        expansion1 = SubElement(ingame, 'ImportFiles', id='Cui_Expansion1', criteria=CRITERIA_1)
        expansion1_p = SubElement(expansion1, 'Properties')
        SubElement(expansion1_p, 'LoadOrder').text = '13'
        for file in mod_files['expansion1']:
            SubElement(expansion1, 'File').text = file
    # mod expansion2
    if 'expansion2' in mod_files:
        expansion2 = SubElement(ingame, 'ImportFiles', id='Cui_Expansion2', criteria=CRITERIA_2)
        expansion2_p = SubElement(expansion2, 'Properties')
        SubElement(expansion2_p, 'LoadOrder').text = '14'
        for file in mod_files['expansion2']:
            SubElement(expansion2, 'File').text = file
    # additions
    if 'additions' in mod_files:
        # import files
        additions = SubElement(ingame, 'ImportFiles', id='Cui_Additions')
        additions_p = SubElement(additions, 'Properties')
        SubElement(additions_p, 'LoadOrder').text = '15'
        for file in mod_files['additions']:
            SubElement(additions, 'File').text = file
        # add user interface
        add_ui = SubElement(ingame, 'AddUserInterfaces', id='Cui_UI')
        add_ui_p = SubElement(add_ui, 'Properties')
        SubElement(add_ui_p, 'Context').text = 'InGame'
        for file in mod_files['additions']:
            if file.endswith('xml'):
                SubElement(add_ui, 'File').text = file

    # Files
    files = SubElement(root, 'Files')
    for _, fs in mod_files.items():
        for file in fs:
            SubElement(files, 'File').text = file

    return root


def __load_files():
    groups = __get_groups(MOD_PATH)
    for name, files in groups.items():
        groups[name] = sorted(list(files))
    return groups


def __get_groups(root_path, groups=None):
    if groups is None:
        groups = dict()
    folders = os.listdir(root_path)
    for folder in folders:
        if folder.endswith('modinfo'):
            continue
        folder_path = os.path.join(root_path, folder)
        if os.path.isdir(folder_path):
            # if it's a dir, then go deeper
            __get_groups(folder_path, groups=groups)
        else:
            # if it's a file, use the folder name as group name
            group_name = root_path.split('\\')[-1]
            files = __get_files(root_path)
            if group_name not in groups:
                groups[group_name] = set()
            groups[group_name].update(files)
    return groups


def __get_files(folder_path):
    file_set = set()
    files = os.listdir(folder_path)
    for file in files:
        # rename all mod files to lower case
        old_name = os.path.join(folder_path, file)
        new_name = os.path.join(folder_path, file.lower())
        os.rename(old_name, new_name)
        # get the relative path for modinfo to use
        relative_path = os.path.relpath(new_name, MOD_PATH)
        file_set.add(relative_path.replace('\\', '/'))
    return file_set


def __prettify(elem):
    raw_string = ElementTree.tostring(elem, encoding='utf-8')
    xml_string = minidom.parseString(raw_string.decode('utf-8'))
    pty_string = xml_string.toprettyxml(indent='  ', encoding='utf-8')
    return pty_string


def __save_modinfo(text):
    with open(MODINFO_PATH, 'w+', encoding='utf-8') as modinfo:
        modinfo.write(text.decode('utf-8'))


def build():
    print('Build modinfo:')
    try:
        print(' - Building...')
        xml_root = __build_modinfo()
        print(' - Prettifing...')
        xml_text = __prettify(xml_root)
        print(' - Saving...')
        __save_modinfo(xml_text)
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
