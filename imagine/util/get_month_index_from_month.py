def handle_int(input_var):
    if isinstance(input_var, int) or (isinstance(input_var, float) and input_var.is_integer()):
        return int(input_var)
    elif isinstance(input_var, str) and input_var.isdigit():
        return int(input_var)
    else:
        return None  # Handle other cases as needed


def get_month_index_from_month(month):

    orig_month = month
    short_months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
    full_months= ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september',
                         'october', 'november', 'december']

    month_strs = []
    if isinstance(month, str):
        month = month.lower()
        if month in short_months:
            return short_months.index(month)
        elif month in full_months:
            return full_months.index(month)
        else:
            raise ValueError(f"month string not recognised. {orig_month}")

    month_int = handle_int(month)
    if month_int is not None and 1 <= month_int <= 12:
        return month_int - 1

    raise ValueError(f"month not recognised: {month}")
