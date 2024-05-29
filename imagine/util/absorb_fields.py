

def absorb_fields(obj, d, fields):
    for field in fields:
        if field in d:
            setattr(obj, field, d[field])


if __name__ == "__main__":

    class MyClass:

        def __init__(self):
            self.a = 1
            self.b = 2

    mc = MyClass()

    d1 = {
            'a': 10,
            'b': 20,
            'c': 30
         }

    fields1 = ['a', 'b', 'e']

    absorb_fields(mc, d1, fields1)

    print(mc.a)
    print(mc.b)
    print(mc.e)
