from pydantic import BaseModel as PydanticBaseModel
import ujson
from typing import Dict
from dotmap import DotMap
from imagine.util.module_helpers import import_module_from_file
from pathlib import Path
from imagine.core import ImagineObject
import copy

#### May want to revist this and change to a json extension that supports comments.
# json5 supports comments.
# json-five supports round trips.


def custom_json_loads(raw_json: str):
    d = ujson.loads(raw_json)

    if "scripts" in d:
        d2 = copy.deepcopy(d)

        # Retain its list of original fields.
        original_field_names = d2.keys()

        # Perform any post-parse work here.
        d, changed_fields = run_scripts(d, 'on_load')
        
        # Keep track of field names that are added by scripts.    
        d.__original_field_names = original_field_names
        __field_names_from_scripts = set(d.keys()) - set(original_field_names)
        d.__field_names_from_scripts = __field_names_from_scripts

        # Or changed by scripts....
        script_modified_original_fields = {k: v for k, v in d2.items() if k in changed_fields}
        d.__original_fields_to_keep = script_modified_original_fields

    return d

def custom_json_dumps(ob: dict):

    # Just dump the input if there's no scripts field.
    if 'scripts' not in ob:
        ujson.dumps(ob)
        return

    # Customise the input to be ready for serialisation.    
    d = run_scripts(ob, 'pre_save')

    # If the scripts modified (or added) fields when loading, 
    # then put those back the way they were. To modify those fields would require
    # modifying the script or underlying data loaded by those scripts.
    # If that's desirable, the pre_save() methods should have already done that.
    original_fields_to_keep = {}
    if "__original_fields_to_keep" in ob:
        original_fields_to_keep = ob["__original_fields_to_keep"]

    field_names_from_scripts = []
    if "__field_names_from_scripts" in ob:
        field_names_from_scripts = ob["__field_names_from_scripts"]

    out_dict = {}
    for k, v in d.items():
        if k[0:2] == "__":
            continue
        if k in field_names_from_scripts:
            continue
        if k in original_fields_to_keep:
            out_dict[k] = original_fields_to_keep[k]
        else:
            out_dict[k] = ob[k]

    # dump the resulting dict to the json string.
    raw_json = ujson.dumps(out_dict)
    return raw_json



class BaseModel(PydanticBaseModel):

    class Config:

        extras = "allow"

        json_loads = custom_json_loads
        json_dumps = custom_json_dumps


def run_scripts(d: Dict, method_name: str):
    
    im_ob = ImagineObject.get_instance()
    if not im_ob.scenario_path:
        return

    all_changed_fields = {}

    if 'scripts' in d: 
        for s in d['scripts']:
            p = Path(im_ob.scenario_path) + s
            m = import_module_from_file("load_save", p) 
            method = getattr(m, method_name)
            d, changed_fields = method(d)
            all_changed_fields += changed_fields
        
    return d, all_changed_fields

