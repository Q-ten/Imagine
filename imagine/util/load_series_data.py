from imagine.util.resolve_imagine_path import resolve_imagine_path
import openpyxl


def load_excel_series_data(series):
    workbook_path = series['excel_workbook']
    workbook_path = resolve_imagine_path(workbook_path)
    range_name = series['range']

    try:
        # Load the workbook
        workbook = openpyxl.load_workbook(workbook_path, data_only=True)
    except FileNotFoundError:
        raise FileNotFoundError(f"Workbook not found: {workbook_path}")

    sheet_name = series.get('excel_sheet')
    if sheet_name:
        if sheet_name not in workbook.sheetnames:
            raise ValueError(f"Worksheet not found: {sheet_name}")
        sheet = workbook[sheet_name]
    else:
        sheet = workbook.active

    if range_name in sheet.defined_names:
        series_range = workbook[sheet.defined_names[range_name]]
    elif range_name in workbook.defined_names:
        series_range = workbook.defined_names[range_name]
    else:
        try:
            series_range = sheet[range_name]
        except Exception as e:
            raise ValueError(f"Range not found: {range_name}")

    # This line is dark magic. List comprehensions seem to have backwards logic for nested iterators
    # And using openpyxl to get named range values is not for the faint-hearted.
    # The list comprehension is like a nested for loop. The inner bit that sets the value is the first expression.
    # But then we have two for loops. Read the left (outer) definition first, then the inner definition.
    # So it's for _sheet_name, address in series_range.destinations:
    #              for cell in workbook[_sheet_name][address]:
    #                   cell[0].value
    data = [cell[0].value
            for _sheet_name, address in series_range.destinations
            for cell in workbook[_sheet_name][address]]

    # Close the workbook
    workbook.close()

    return data


def load_series_data(series):
    if isinstance(series, list):
        return series
    elif isinstance(series, dict) and 'excel_workbook' in series and 'range' in series:
        return load_excel_series_data(series)
    else:
        raise ValueError("Invalid series")


def resolve_series(data):
    if isinstance(data, dict):
        for key, value in data.items():
            if key == "series":
                data[key] = load_series_data(value)
            else:
                data[key] = resolve_series(value)
    elif isinstance(data, list):
        for i in range(len(data)):
            data[i] = resolve_series(data[i])
    return data

