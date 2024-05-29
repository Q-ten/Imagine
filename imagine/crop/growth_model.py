import abc
from imagine.util.underscore import underscore
from dotwiz import DotWiz

""" In Matlab Imagine, the GrowthModel class wrapped an Abstract GrowthModelDelegate class.
    This was due to the need to have an array of GrowthModels of the same type. Each growth model object
    would have a delegate (with the delegate being a specific concrete instance that subclassed an
    abstract GrowthModelDelegate class). The GrowthModel class simply wrapped the delegate class.
"""

"""
    % GrowthModel is an abstract class which will be an interface for the
    % GrowthModels that are used in Imagine.
    % It will be responsible for modelling the growth of a crop, and so
    % will have it's state, a state propagation function and output
    % functions. 
    % The GrowthModel will also need to respond to Events (ImagineEvents,
    % not MATLAB object events. These events may or may not alter the state
    % and may or may not produce saleable products.
    % A GrowthModel will also need to inform other objects what 
    % ImagineEvents and Products are supported. So while the productNames
    % will be and imagineEventNames will be protected, we need to let other
    % objects get them.
    
"""

"""
    The growth model doesn't retain state. It takes state as input, performs modifications and returns state as output.
    State is retained inside a PlantedCrop.
"""



class GrowthModel(abc.ABC):

    transition_function_prefix = "transition_function_"

    def __init__(self):
        self._supported_imagine_events = None
        self._growth_model_initial_events = []
        self._growth_model_regular_events = []
        self._growth_model_destruction_events = []
        self._growth_model_financial_events = []

    @abc.abstractmethod
    def load_gm(self, d):
        pass

    @property
    def growth_model_initial_events(self):
        return self._growth_model_initial_events

    @property
    def growth_model_regular_events(self):
        return self._growth_model_regular_events

    @property
    def growth_model_destruction_events(self):
        return self._growth_model_destruction_events

    @property
    def growth_model_financial_events(self):
        return self._growth_model_financial_events


    @property
    # TODO: revise this to return a dict?
    def growth_model_events(self):
        evts = self.growth_model_initial_events + \
               self.growth_model_regular_events + \
               self.growth_model_destruction_events + \
               self.growth_model_financial_events
        return evts

    # TODO: remove this note once fully resolved.
    # Removing product_price_models from GrowthModel. The price models will be part of a Crop now.
    # May need to provide the product rates though. Perhaps that's done through empty transition function calls.
    # @property
    # @abc.abstractmethod
    # def product_price_models(self):
    #     pass

    # @property
    # @abc.abstractmethod
    # def product_price_rates(self):
    #     pass
    #
    # @property
    # @abc.abstractmethod
    # def cost_price_rates(self):
    #     pass

    # @property
    # @abc.abstractmethod
    # def growth_model_output_units(self):
    #     pass
    #
    # @property
    # @abc.abstractmethod
    # def growth_model_output_rates(self):
    #     pass

    @property
    @abc.abstractmethod
    def model_name(self):
        pass

    @property
    @abc.abstractmethod
    def supported_categories(self):
        pass

    @property
    @abc.abstractmethod
    def state_description(self):
        pass

    @abc.abstractmethod
    def gm_is_valid(self):
        pass

    @abc.abstractmethod
    def gm_is_ready(self):
        pass

    @abc.abstractmethod
    def propagate_state(self, planted_crop, sim):
        pass

    # @abc.abstractmethod
    # def setup_growth_model(self, crop_name):
    #     pass
    #
    # @abc.abstractmethod
    # def render_growth_model(self, ax):
    #     pass

    def event_transition(self, event_name, planted_crop, sim):
        func_name = self.transition_function_prefix + underscore(event_name)
        transition_func = getattr(self, func_name, None)
        if transition_func:
            return transition_func(planted_crop, sim)
        return [], []

    @abc.abstractmethod
    def calculate_outputs(self, state):
        pass

    # @abc.abstractmethod
    # def crop_name_has_changed(self, previous_name, new_name):
    #     pass

    @property
    def supported_imagine_events(self):
        if self._supported_imagine_events is None:
            trans_fcns = []
            for method_name in dir(self.__class__):
                if method_name.startswith(self.transition_function_prefix):
                    fcn = method_name[len(self.transition_function_prefix):].replace('_', ' ')
                    trans_fcns.append(fcn)
            return trans_fcns
        else:
            return self._supported_imagine_events

    @property
    def state_size(self):
        return len(self.state_description)

    # TODO: remove these methods. Use the get___rates methods below instead.
    # def get_event_output_units(self, event_name):
    #     method_name = self.transition_function_prefix + event_name.replace(' ', '_')
    #     _, eos = getattr(self, method_name)(None, None)
    #     event_output_units = [eo.unit for eo in eos]
    #     return event_output_units
    #
    # def get_output_product_units(self, event_name):
    #     method_name = self.transition_function_prefix + event_name.replace(' ', '_')
    #     ops, _ = getattr(self, method_name)(None, None)
    #     event_output_units = [op.unit for op in ops]
    #     return event_output_units

    # These 3 methods get columns of empty Rates that will have the units and denominator units
    # that will be produced by the growth model.
    #
    #
    # Get product and event output rates for the given event.
    def get_event_output_rates(self, event_name):
        method_name = self.transition_function_prefix + event_name.lower().replace(' ', '_')
        if not hasattr(self, method_name):
            return [], []
        product_rates, event_output_rates = getattr(self, method_name)(None, None)
        return product_rates, event_output_rates

    # Get the output rates. (I.e. from calculate_outputs which is the view of the state.)
    def get_output_rates(self):
        output_rates = self.calculate_outputs()
        return output_rates

    # Get the product rates from propagate state.
    def get_propagation_product_rates(self):
        _, product_rates = self.propagate_state(None, None)
        return product_rates

    # Get an event by its name,
    def get_event_by_name(self, event_name):
        found_evt = [evt for evt in self.growth_model_events if evt.name == event_name]
        if len(found_evt) == 1:
            return found_evt[0]
        else:
            raise ValueError(f"event_name {event_name} does not match exactly one of the growth model's events.")

# A helper to set up a structure to store unit lists.
def make_growth_model_units():
    out = DotWiz()
    out.outputs = {}
    out.propagation_products = {}
    out.products = {}
    out.event_outputs = {}

    # These default to empty lists. Only need to implement non-empty ones.
    out.outputs.numerator_units = []
    out.outputs.denominator_units = []
    out.propagation_products.numerator_units = []
    out.propagation_products.denominator_units = []

    # Index these by event name.
    out.products.numerator_units = {}
    out.products.denominator_units = {}
    out.event_outputs.numerator_units = {}
    out.event_outputs.denominator_units = {}

    return out
