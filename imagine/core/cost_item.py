from typing import List, Optional
from imagine.core.amount import Amount
from imagine.core.rate import Rate


class CostItem:
    def __init__(
        self,
        event_name: Optional[str] = None,
        price_model: Optional["PriceModel"] = None,
        planted_crop: Optional["PlantedCrop"] = None,
        sim: Optional["Simulation"] = None,
        event_output_amounts: Optional[List[Amount]] = None,
        product_amounts: Optional[List[Amount]] = None,
    ):
        if event_name is None:
            return
        elif (
            event_name is not None
            and price_model is not None
            and planted_crop is not None
            and sim is not None
            and event_output_amounts is not None
            and product_amounts is not None
        ):
            self.cost_name = price_model.name
            self.event_name = event_name
            self.price_model = price_model
            self.price = sim.get_price(price_model)
            got_amount = False

            for eoa in event_output_amounts:
                if eoa.unit == self.price.denominator_unit:
                    self.quantity = eoa
                    got_amount = True
                    break

            if not got_amount:
                for pa in product_amounts:
                    if pa.unit == self.price.denominator_unit:
                        self.quantity = pa
                        got_amount = True
                        break

            if not got_amount:
                self.quantity = planted_crop.get_amount(self.price.denominator_unit)
                if self.quantity:
                    got_amount = True

            if not got_amount:
                recent_production = planted_crop.get_most_recent_production(
                    self.price.denominator_unit.measurable
                )
                if recent_production:
                    self.quantity = recent_production

            if not self.quantity:
                raise ValueError(
                    "CostItem creation failed because the quantity to match the price cannot be found."
                )
        else:
            raise ValueError("CostItem class requires 0 or 6 arguments to the Constructor.")

    @property
    def cost(self):
        return self.quantity * self.price
