def number_to_placing(n):
    if isinstance(n, int) and n > 0:
        if n % 100 in [11, 12, 13]:
            p = str(n) + "th"
        else:
            last_digit = n % 10
            if last_digit == 1:
                p = str(n) + "st"
            elif last_digit == 2:
                p = str(n) + "nd"
            elif last_digit == 3:
                p = str(n) + "rd"
            else:
                p = str(n) + "th"
        return p
    else:
        return None
