import xlsxwriter
from xlsxwriter.utility import xl_rowcol_to_cell
from pathlib import Path
from dotwiz import DotWiz

from imagine.core.amount import Amount

# Define constants
# This is the default row height in Excel. Unfortunately,
# there doesn't seem to be a way of getting this programmatically, at least with xlsxwriter.
DEFAULT_ROW_HEIGHT = 14.3


def check_path_available(path):
    if not path.parent.exists():
        return False
    if path.exists():
        return False
    return True


class SimWriter:

    def __init__(self, sims=None, filepath=None):
        self.sims = sims
        self.filepath = Path(filepath) if filepath else None

        self.wb = None
        self.ws = None
        self.cursor_row = None
        self.sim = None

        self.formats = None
        self.setup_columns()

        from imagine.core import ImagineObject
        im_ob = ImagineObject.get_instance()
        self.simulation_length = im_ob.simulation_length

        self.references = None

    @classmethod
    def setup_columns(cls):
        column_defs = ('regime_crop_col',
                       "event_col",
                       "event_sub_col",
                       "ref1_col",
                       "ref2_col",
                       "ref1_str_col",
                       "ref2_str_col",
                       "pre_data_col",
                       "data_col",
                       )
        d = DotWiz()
        for ix, col in enumerate(column_defs):
            d[col] = ix
            print(col)

        d.title_col = 0
        d.header_col = 0
        d.climate_series_col = 0
        d.amount_name_col = d.ref1_str_col
        d.amount_units_col = d.ref2_str_col
        d.amount_longhand_col = d.pre_data_col
        cls.coldefs = d

        colwidths = [20, 20, 8, 8, 8, 30, 8, 10]
        cls.colwidths = colwidths

        return d, colwidths

    def register_formats(self, wb):

        fmts = DotWiz()
        fmts.title_format = wb.add_format({'font_size': 20, 'bold': True})
        fmts.header_format = wb.add_format({'font_size': 16, 'bold': True})
        fmts.total_format = wb.add_format({'bold': True})
        fmts.total_dollar_format = wb.add_format({'bold': True, 'num_format': '$#,##0'})
        fmts.two_dp_format = wb.add_format({'num_format': '0.00'})
        fmts.right_justify_format = wb.add_format({'align': 'right'})
        fmts.prevent_spill_format = wb.add_format({'align': 'top', 'text_wrap': True})

        self.formats = fmts
        return fmts

    def write_sims_to_file(self, sims=None, filepath=None):
        self.sims = sims if sims else self.sims
        self.filepath = Path(filepath) if filepath else self.filepath
        if not self.sims:
            print("No sims set.")
            return
        if not self.filepath:
            print("No filepath set.")
            return

        if not check_path_available(self.filepath):
            try:
                self.filepath.parent.mkdir(parents=True, exist_ok=True)
            except Exception as e:
                raise ValueError(f"Save path is not valid. {e}")

        self.wb = xlsxwriter.Workbook(self.filepath)
        self.formats = self.register_formats(self.wb)

        print(self.filepath.resolve())

        for ix, sim in enumerate(self.sims):
            sim_name = sim.sim_name if sim.sim_name else f"Sim {ix + 1}"
            self.ws = self.wb.add_worksheet(sim_name)
            self.sim = sim
            self.write_sim()

            for col, col_width in enumerate(self.colwidths):
                self.ws.set_column(col, col, col_width)

        self.wb.close()

    def write_sim(self):

        self.cursor_row = 0
        self.references = DotWiz()

        # Write the header.
        self.write_title()

        # Start off with the prices and then climate series.
        # Start with prices because they're defined in years. Then move on to monthly definitions.
        self.write_prices()
        self.write_climate_series()

        self.write_regime_outputs()
        self.write_outputs()
        self.write_event_names()
        self.write_event_outputs()
        self.write_production()
        self.write_income()
        self.write_costs()
        self.write_gross_margin()

    def write_title(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        cursor_row = self.cursor_row

        # Put the sheet name in at the top and bold it.
        ws.write(cursor_row, coldefs.header_col, ws.name, formats.title_format)
        cursor_row += 1
        cursor_row += 1
        self.cursor_row = cursor_row

    def write_climate_series(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row

        ws.write(cursor_row, coldefs.climate_series_col, "Climate Series", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        for series_name, cs in sim.sim_store.climate_store.items():
            ws.write(cursor_row, coldefs.climate_series_col, series_name)
            ws.write_row(cursor_row, coldefs.data_col, tuple(cs.flat), formats.two_dp_format)
            cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_prices(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row

        ws.write(cursor_row, coldefs.climate_series_col, "Income Prices", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Year", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length + 1))
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        for crop in crop_mgr.crops:
            product_price_table = sim.sim_store.crop_store[crop.name].product_price_table
            for ix, pm in enumerate(crop.price_config.product_price_models):
                yearly_prices = product_price_table[:, ix]
                ws.write(cursor_row, coldefs.regime_crop_col, "--")
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, pm.name)
                ws.write(cursor_row, coldefs.amount_name_col, pm.rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, pm.rate.amount_unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, pm.rate.amount_unit_longhand,
                         formats.prevent_spill_format)
                ws.write_row(cursor_row, coldefs.data_col, yearly_prices, formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1
        cursor_row += 1

        ws.write(cursor_row, coldefs.climate_series_col, "Cost Prices", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Year", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length + 1))
        cursor_row += 1

        for crop in crop_mgr.crops:
            cost_price_table = sim.sim_store.crop_store[crop.name].cost_price_table
            for ix, pm in enumerate(crop.price_config.cost_price_models):
                yearly_prices = cost_price_table[:, ix]
                ws.write(cursor_row, coldefs.regime_crop_col, "--")
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, pm.name)
                ws.write(cursor_row, coldefs.amount_name_col, pm.rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, pm.rate.amount_unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, pm.rate.amount_unit_longhand,
                         formats.prevent_spill_format)
                ws.write_row(cursor_row, coldefs.data_col, yearly_prices, formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1
        cursor_row += 1

        self.cursor_row = cursor_row

    def write_regime_outputs(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Regime Outputs", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.regime.regime_manager import RegimeManager
        regime_mgr = RegimeManager.get_instance()

        for regime in regime_mgr.regimes:
            output_rates = regime.regime_rate_defs.output_rates
            outputs = sim.sim_store.regime_store[regime.regime_label].outputs
            for ix, output_rate in enumerate(output_rates):
                monthly_outputs = outputs[:, ix]
                ws.write(cursor_row, coldefs.regime_crop_col, regime.regime_label)

                ws.write(cursor_row, coldefs.amount_name_col, output_rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, output_rate.amount_unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, output_rate.amount_unit_longhand,
                         formats.prevent_spill_format)

                ws.write_row(cursor_row, coldefs.data_col, (op.number if op else None for op in monthly_outputs),
                             formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_outputs(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Outputs", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        for crop in crop_mgr.crops:
            output_rates = crop.crop_rate_defs.output_rates
            outputs = sim.sim_store.crop_store[crop.name].outputs
            output_count = len(output_rates)
            for ix, output_rate in enumerate(output_rates):
                month_start_outputs = outputs[:, ix]
                ws.write(cursor_row, coldefs.regime_crop_col, "--")
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, 'Month Start')
                ws.write(cursor_row, coldefs.amount_name_col, output_rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, output_rate.amount_unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, output_rate.amount_unit_longhand,
                         formats.prevent_spill_format)

                ws.write_row(cursor_row, coldefs.data_col, (op.number if op else None for op in month_start_outputs),
                             formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1

            for ix, output_rate in enumerate(output_rates):
                month_end_outputs = outputs[:, ix + output_count]
                ws.write(cursor_row, coldefs.regime_crop_col, "--")
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, 'Month End')
                ws.write(cursor_row, coldefs.amount_name_col, output_rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, output_rate.amount_unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, output_rate.amount_unit_longhand,
                         formats.prevent_spill_format)
                ws.write_row(cursor_row, coldefs.data_col,
                             (op.number if op else None for op in month_end_outputs), formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_event_outputs(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Event Outputs", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        for crop in crop_mgr.crops:
            for event_type, events in crop.all_events.items():
                for event in events:
                    event_outputs = sim.sim_store.crop_store[crop.name].events[event.name].event_outputs
                    if event_outputs.size == 0:
                        continue
                    event_output_rates = crop.crop_rate_defs.events[event.name].event_output_rates
                    event_output_amounts = [Amount(0, eor.unit) for eor in event_output_rates]
                    for ix, event_output_amount in enumerate(event_output_amounts):
                        ws.write(cursor_row, coldefs.regime_crop_col, "--")
                        ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                        ws.write(cursor_row, coldefs.event_col, event.name)
                        ws.write(cursor_row, coldefs.amount_name_col, event_output_amount.amount_name)
                        ws.write(cursor_row, coldefs.amount_units_col, event_output_amount.amount_unit_symbol)
                        ws.write(cursor_row, coldefs.amount_longhand_col, event_output_amount.amount_unit_longhand,
                                 formats.prevent_spill_format)
                        ws.write_row(cursor_row, coldefs.data_col, (eo.number if eo else None for eo in
                                                                    event_outputs[:, ix]),
                                     formats.two_dp_format)
                        ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                        cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_production(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Production", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        for crop in crop_mgr.crops:

            # Add propagation products if there are any
            prop_prod_rates = crop.crop_rate_defs.propagation_product_rates
            prop_products = sim.sim_store.crop_store[crop.name].propagation_products
            for ix, product_rate in enumerate(prop_prod_rates):
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, "Monthly Propagation")
                ws.write(cursor_row, coldefs.amount_name_col, product_rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, product_rate.unit.unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, product_rate.unit.unit_longhand,
                         formats.prevent_spill_format)
                ws.write_row(cursor_row, coldefs.data_col, (op.quantity.number if op else None for op in
                                                            prop_products[:, ix]),
                             formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1

            for event_type, events in crop.all_events.items():
                for event in events:
                    products = sim.sim_store.crop_store[crop.name].events[event.name].products
                    product_rates = crop.crop_rate_defs.events[event.name].product_rates
                    for ix, product_rate in enumerate(product_rates):
                        ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                        ws.write(cursor_row, coldefs.event_col, event.name)
                        ws.write(cursor_row, coldefs.amount_name_col, product_rate.amount_name)
                        ws.write(cursor_row, coldefs.amount_units_col, product_rate.unit.unit_symbol)
                        ws.write(cursor_row, coldefs.amount_longhand_col, product_rate.unit.unit_longhand,
                                 formats.prevent_spill_format)
                        ws.write_row(cursor_row, coldefs.data_col, (op.quantity.number if op else None for op in
                                                                    products[:, ix]),
                                     formats.two_dp_format)
                        ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                        cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_event_names(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Occurrences", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        for crop in crop_mgr.crops:
            event_lists = [', '.join(event_list) for event_list in sim.sim_store.crop_store[crop.name].events_triggered]
            ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
            ws.write_row(cursor_row, coldefs.data_col, event_lists, formats.prevent_spill_format)
            ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
            cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_income(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Income", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))     # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()
        top_income_row = cursor_row

        for crop in crop_mgr.crops:

            # Add propagation products if there are any
            prop_prod_rates = crop.crop_rate_defs.propagation_product_rates
            prop_products = sim.sim_store.crop_store[crop.name].propagation_products
            for ix, product_rate in enumerate(prop_prod_rates):
                price_model = crop.get_product_price_model(product_rate.unit)
                ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                ws.write(cursor_row, coldefs.event_col, "Monthly Propagation")
                ws.write(cursor_row, coldefs.amount_name_col, price_model.rate.amount_name)
                ws.write(cursor_row, coldefs.amount_units_col, price_model.rate.unit.unit_symbol)
                ws.write(cursor_row, coldefs.amount_longhand_col, price_model.rate.unit.unit_longhand,
                         formats.prevent_spill_format)
                ws.write_row(cursor_row, coldefs.data_col, (op.income.number if op else None for op in
                                                            prop_products[:, ix]),
                             formats.two_dp_format)
                ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                cursor_row += 1

            for event_type, events in crop.all_events.items():
                for event in events:
                    products = sim.sim_store.crop_store[crop.name].events[event.name].products
                    product_rates = crop.crop_rate_defs.events[event.name].product_rates
                    for ix, product_rate in enumerate(product_rates):
                        price_model = crop.get_product_price_model(product_rate.unit)
                        ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                        ws.write(cursor_row, coldefs.event_col, event.name)
                        ws.write(cursor_row, coldefs.amount_name_col, price_model.rate.amount_name)
                        ws.write(cursor_row, coldefs.amount_units_col, price_model.rate.unit.unit_symbol)
                        ws.write(cursor_row, coldefs.amount_longhand_col, price_model.rate.unit.unit_longhand,
                                 formats.prevent_spill_format)
                        ws.write_row(cursor_row, coldefs.data_col, (op.income.number if op else None for op in
                                                                    products[:, ix]),
                                     formats.two_dp_format)
                        ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                        cursor_row += 1

        lower_income_row = cursor_row - 1
        # Implement the income total row.
        ws.write(cursor_row, coldefs.amount_name_col, "Total", formats.total_format)
        ws.write(cursor_row, coldefs.amount_units_col, "$")
        for ix in range(0, self.simulation_length * 12):
            top_cell = xl_rowcol_to_cell(top_income_row, coldefs.data_col + ix)
            lower_cell = xl_rowcol_to_cell(lower_income_row, coldefs.data_col + ix)
            formula = f"=SUM({top_cell}:{lower_cell})"
            ws.write(cursor_row, coldefs.data_col + ix, formula)
        self.references.income_total_row = cursor_row
        cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_costs(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Cost Items", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))  # 12 months in year.
        cursor_row += 1

        from imagine.crop.crop_manager import CropManager
        crop_mgr = CropManager.get_instance()

        top_costs_row = cursor_row
        for crop in crop_mgr.crops:
            for event_type, events in crop.all_events.items():
                for event in events:
                    cost_price_models = crop.get_cost_price_models(event.name)
                    cost_items = sim.sim_store.crop_store[crop.name].events[event.name].cost_items
                    for ix, cost_price_model in enumerate(cost_price_models):
                        ws.write(cursor_row, coldefs.regime_crop_col, crop.name)
                        ws.write(cursor_row, coldefs.event_col, event.name)
                        ws.write(cursor_row, coldefs.amount_name_col, cost_price_model.rate.amount_name)
                        ws.write(cursor_row, coldefs.amount_units_col, cost_price_model.rate.unit.unit_symbol)
                        ws.write(cursor_row, coldefs.amount_longhand_col, cost_price_model.rate.unit.unit_longhand,
                                 formats.prevent_spill_format)
                        ws.write_row(cursor_row, coldefs.data_col, (ci.cost.number if ci else None for ci in
                                                                    cost_items[:, ix]),
                                     formats.two_dp_format)
                        ws.set_row(cursor_row, DEFAULT_ROW_HEIGHT)
                        cursor_row += 1


        # Implement the costs total row.
        lower_costs_row = cursor_row - 1
        ws.write(cursor_row, coldefs.amount_name_col, "Total", formats.total_format)
        ws.write(cursor_row, coldefs.amount_units_col, "$")
        for ix in range(0, self.simulation_length * 12):
            top_cell = xl_rowcol_to_cell(top_costs_row, coldefs.data_col + ix)
            lower_cell = xl_rowcol_to_cell(lower_costs_row, coldefs.data_col + ix)
            formula = f"=SUM({top_cell}:{lower_cell})"
            ws.write(cursor_row, coldefs.data_col + ix, formula)
        self.references.costs_total_row = cursor_row
        cursor_row += 1

        cursor_row += 1
        self.cursor_row = cursor_row

    def write_gross_margin(self):
        ws = self.ws; sim = self.sim; coldefs = self.coldefs; formats = self.formats; cursor_row = self.cursor_row
        ws.write(cursor_row, coldefs.climate_series_col, "Gross Margin", formats.header_format)
        ws.write(cursor_row, coldefs.data_col - 1, "Month", formats.right_justify_format)
        ws.write_row(cursor_row, coldefs.data_col, range(1, self.simulation_length * 12 + 1))  # 12 months in year.
        cursor_row += 1

        ws.write(cursor_row, coldefs.amount_name_col, "Monthly Gross Margin", formats.total_format)
        ws.write(cursor_row, coldefs.amount_units_col, "$")

        for ix in range(0, self.simulation_length * 12):
            income_cell = xl_rowcol_to_cell(self.references.income_total_row, coldefs.data_col + ix)
            costs_cell = xl_rowcol_to_cell(self.references.costs_total_row, coldefs.data_col + ix)
            formula = f"={income_cell}-{costs_cell}"
            ws.write(cursor_row, coldefs.data_col + ix, formula)
        self.references.gm_total_row = cursor_row
        cursor_row += 1

        # Sum the total for all the years.
        cursor_row += 1
        cursor_row += 1
        ws.write(cursor_row, coldefs.amount_name_col, "Sim Gross Margin", formats.total_format)
        ws.write(cursor_row, coldefs.amount_units_col, "$")
        first_gm_cell = xl_rowcol_to_cell(self.references.gm_total_row, coldefs.data_col)
        last_gm_cell = xl_rowcol_to_cell(self.references.gm_total_row, coldefs.data_col+self.simulation_length*12-1)
        formula = f"=SUM({first_gm_cell}:{last_gm_cell})"
        ws.write(cursor_row, coldefs.data_col-1, formula, formats.total_dollar_format)

        cursor_row += 1
        self.cursor_row = cursor_row

