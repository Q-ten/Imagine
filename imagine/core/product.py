"""
% A product contains the data needed to record a product that's been
% produced as a result of an event taking place - probably a harvest event.
%
% There will be a quantity of product, and there will be the price it was
% sold for and the income generated.
"""
from imagine.core.amount import Amount


class Product:

    """
        % quantity - An Amount, the quantity of stuff produced that the price should be applied to.
        % The quantity here is a little different to the quantity in
        % CostItem because the units of this quantity really specify what
        % the product is and where the income comes from. ProductName is
        % not needed as the quantity defines the Unit of what is produced.
        quantity
        
        % A price Rate, usually in dollars, that will be applied to the quantity.
        price

    """
    def __init__(self, crop_name: str, amount: Amount, price_model, sim):
        if crop_name is None and amount is None and price_model is None and sim is None:
            return
        elif crop_name is not None and amount is not None and price_model is not None and sim is not None:
            self.quantity = amount
            self.price = sim.get_price(price_model)
        else:
            raise ValueError("Product class requires 0 or 4 arguments to the constructor.")

    @property
    def income(self):
        return self.quantity * self.price
