

def exists(d, access_string):
    try:
        result = eval("d" + access_string, {'d': d})
        return result is not None
    except Exception:
        return False
