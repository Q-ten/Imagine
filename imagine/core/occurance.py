from imagine.core.amount import Amount
from imagine.core.unit import Unit
from imagine.core.cost_item import CostItem
from imagine.core.product import Product


class Occurrence:
    def __init__(self, event_name, product_amounts, event_output_amounts, planted_crop, sim):
        self.event_name = event_name
        self.month_index = sim.month_index
        self.month_day = sim.month_day

        # no_cost = event_name == "Monthly Propagation"

        self.event_outputs = event_output_amounts if event_output_amounts is not None else []

        # if not no_cost:
        #     self.cost_items = [CostItem(event_name, planted_crop, sim, event_output_amounts, product_amounts)]
        # else:
        #     self.cost_items = []
        if event_name == "Monthly Propagation":
            self.cost_items = []
        else:
            self.cost_items = [CostItem(event_name, price_model, planted_crop, sim, event_output_amounts, product_amounts)
                               for price_model in planted_crop.crop_object.get_cost_price_models(event_name)]

        prod_price_models = [planted_crop.crop_object.get_product_price_model(pa.unit) for pa in product_amounts]

        prods = [Product(planted_crop.crop_object.name, amount, price_model, sim) for amount, price_model in
                 zip(product_amounts, prod_price_models)] if product_amounts else []
        self.products = prods

        sim.sim_store.add_occurrence_to_crop(self, planted_crop.crop_object.name)

    @property
    def event_cost(self):
        e_c = Amount(0, Unit('', 'Money', 'Dollar'))
        for cost_item in self.cost_items:
            e_c += cost_item.cost
        return e_c

    @property
    def event_income(self):
        e_in = Amount(0, Unit('', 'Money', 'Dollar'))
        for product in self.products:
            e_in += product.income
        return e_in

    @property
    def event_profit(self):
        return self.event_income - self.event_cost
