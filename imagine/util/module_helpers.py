import importlib.util

loaded_modules = {}

def import_module_from_file(module_name, file_path):
    if file_path in loaded_modules:
        return loaded_modules[file_path]

    try:
        spec = importlib.util.spec_from_file_location(module_name, file_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        
        loaded_modules[file_path] = module
    except Exception as error:
        print('Exception loading module:', error)
        raise error

    return module


