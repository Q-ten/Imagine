class BiDirectionalMap:
    def __init__(self):
        self.key_to_value = {}
        self.value_to_key = {}

    def insert(self, key, value):
        self.key_to_value[key] = value
        self.value_to_key[value] = key

    def get_by_key(self, key):
        return self.key_to_value.get(key)

    def get_by_value(self, value):
        return self.value_to_key.get(value)


class UnitSymbolRegistry:
    def __init__(self):
        self._map = BiDirectionalMap()

    def insert(self, name, symbol):
        self._map.insert(name, symbol)

    def get_symbol_from_name(self, name):
        if name in self._map.key_to_value:
            return self._map.get_by_key(name)
        else:
            return None

    def get_name_from_symbol(self, symbol):
        if symbol in self._map.value_to_key:
            return self._map.get_by_value(symbol)
        else:
            return None
