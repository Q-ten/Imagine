"""
This class holds information to assist with event processing.
"""


class EventPriceMapping:

    def __init__(self):

        # Reference to the ImagineEvent in the crop object.
        self.event = None

        # Indices into the relevant price models list / table
        self.product_price_model_indices = []
        self.cost_price_model_indices = []

        # Get the list of empty product rates and event output rates.
        # When product and event_outputs are returned from this event's transition function
        # they will match these lists of nominal (0) rates here. The useful bit is the unit and denominator unit.
        self.event_products_rates = []
        self.event_outputs_rates = []

        # Simply the unit extracted from the rates.
        self.event_products_units = []
        self.event_outputs_units = []

        # A subset of the full price model list corresponding to the indices for this event.
        self.product_price_models = []
        self.cost_price_models = []

