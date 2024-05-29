from imagine.core import ImagineObject


def resolve_imagine_path(input_path):

    if not isinstance(input_path, str):
        raise ValueError(f"input_path should be a string. Provided type: {type(input_path)}")

    im_ob = ImagineObject.get_instance()
    fields = im_ob.folders.keys()
    output_path = input_path
    if "$Resources" in fields:
        output_path = output_path.replace("$Resources", str(im_ob.folders["$Resources"]))
    if "$Scenario" in fields:
        output_path = output_path.replace("$Scenario", str(im_ob.folders["$Scenario"]))

    return output_path
