import numpy as np

class DTypeAccessorFactory:
    @classmethod
    def create_accessor_class(cls, dtype):
        class_name = f"{dtype.name}_Accessor"
        fields = dtype.fields.keys()

        def init(self, void_obj):
            if void_obj.dtype != self._dtype:
                raise ValueError("The provided numpy.void object does not match the specified dtype")
            self._void_obj = void_obj

        def create_property(field):
            def getter(self):
                return self._void_obj[field]

            def setter(self, value):
                self._void_obj[field] = value

            return property(getter, setter)

        properties = {field: create_property(field) for field in fields}
        properties['__init__'] = init
        properties['dtype'] = classmethod(property(lambda cls: cls._dtype))

        # Create the class with the hidden _dtype field
        accessor_class = type(class_name, (object,), properties)
        accessor_class._dtype = dtype  # Store the dtype as a hidden class-level field
        return accessor_class

if __name__ == "__main__":

    # Example usage
    my_dtype = np.dtype([('field1', np.int32), ('field2', np.float64), ('ob', 'O')])
    MyDTypeAccessor = DTypeAccessorFactory.create_accessor_class(my_dtype)

    arr = np.zeros(10, dtype=my_dtype)

    ob = MyDTypeAccessor(arr[0])
    ob.field1 += 10
    ob.ob = "hello!"
    print(ob.field1)
    print(ob.ob)

    print(arr['field1'])

    print(arr)

    print(ob.__class__.dtype)
