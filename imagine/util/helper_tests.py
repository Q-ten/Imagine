from collections.abc import Iterable
import numpy as np

# Test for whether an object is list like.
# May require that all items pass a provided test.
_max_len = 600


def is_int(x):
    return isinstance(x, int) or np.issubdtype(type(x), np.integer)


def is_list_like(arg1, required_test=None):
    tf = isinstance(arg1, Iterable) and hasattr(arg1, '__len__') and hasattr(arg1, '__getitem__')
    if tf and callable(required_test):
        it = iter(arg1)
        try:
            for _ in range(_max_len):
                item = next(it)
                if not required_test(item):
                    tf = False
                    break
        except StopIteration:
            # If the end of the iter is reached without returning False
            # then all the items are the required type.
            tf = True

    return tf


# return a test function. Checks the input is numeric and has the shape provided (if provided).
def is_numeric_array(shape=None):
    def is_numeric(arr):
        if isinstance(arr, (list, np.ndarray)):
            arr_shape = np.shape(arr)
            arr_shape = arr_shape if len(arr_shape) > 1 else arr_shape[0]
            if shape is not None and arr_shape != shape:
                return False
            return all(isinstance(x, (int, float, np.number)) for x in np.ravel(arr))
        else:
            return False
    return is_numeric


if __name__ == "__main__":

    d = {
        "a": [1, 2, 3],
        "b": ["a", "b", "c"],
        "c": [1, 2, None],
        "d": [1, 2, "c"],
        "e": range(10),
        "f": [1, 2, 3.0],
        "g": {"x": 100, "y": 200, "z": 300},
        "h": {"x": 100, "y": 200, "z": {}},
        "i": np.arange(10, 100, 10)

    }

    for key, val in d.items():
        print(f"{key}:, {val}")
        print(f"is list:         {is_list_like(val)}")
        print(f"is list of ints: {is_list_like(val, is_int)}\n")

    # Example usage
    check_array = is_numeric_array((2, 3))

    arr1 = [[1, 2, 3], [4, 5, 6]]  # Example list with numeric values
    arr2 = np.array([[1, 2, 3], [4, 'a', 6]])  # Example numpy array with non-numeric value
    arr3 = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])  # Example numpy array with different shape

    print(check_array(arr1))  # Output: True
    print(check_array(arr2))  # Output: False
    print(check_array(arr3))  # Output: False
