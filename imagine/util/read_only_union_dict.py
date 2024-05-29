import collections
import types
import copy

# class ReadOnlyUnionDict(collections.ChainMap):
#     def __init__(self, *dicts):
#         readonly_dicts = [types.MappingProxyType(d) for d in dicts]
#         super().__init__(*readonly_dicts)

class ReadOnlyUnionDict(dict):
    def __init__(self, *dicts):
        self._chain_map = collections.ChainMap(*dicts)

    def __getitem__(self, key):
        return self._chain_map[key]

    def __setitem__(self, key, value):
        raise TypeError("Cannot modify a read-only dictionary")


def get_deep_union_dict(*dicts):
    deep_copied_dicts = [copy.deepcopy(dict) for dict in dicts]
    chain_map = collections.ChainMap(*deep_copied_dicts)
    return dict(chain_map)


if __name__ == "__main__":

    # Example usage
    dict1 = {'a': 1, 'b': 2}
    dict2 = {'b': 3, 'c': 4}
    dict3 = {'c': 5, 'd': 6}

    # Create an instance of ReadOnlyUnionDict with the set of dictionaries
    read_only_dict = ReadOnlyUnionDict(dict1, dict2, dict3)

    # Access the read-only union directly
    print(read_only_dict['a'])  # Output: 1
    print(read_only_dict['b'])  # Output: 2 (from dict1)
    print(read_only_dict['c'])  # Output: 4 (from dict2)
    print(read_only_dict['d'])  # Output: 6

