from typing import Optional
from imagine.events.imagine_event_status import ImagineEventStatus
#from pimagine.events.trigger import Trigger
from imagine.events.condition_syntax import eval_condition_dictionary


class ImagineEvent:
    """
    An ImagineEvent defines when in the lifecycle of a crop some event
    should occur, and what happens when it does.
    """

    def __init__(self, name: str, status, trigger=None): #, cost_price_model=None):
        if isinstance(name, str):
            self.name = name
        else:
            raise ValueError("First argument to ImagineEvent constructor must be a string.")

        if isinstance(status, ImagineEventStatus):
            self.status = status
        else:
            raise ValueError("Second argument to ImagineEvent constructor must be an ImagineEventStatus object.")

#        self.cost_price_model = cost_price_model
        # Initialise triggers to None
        self.private_redefined_trigger = None
        self.private_trigger = None
        # Set trigger if provided.

        if trigger:
            self.trigger = trigger

    @property
    def trigger(self):
        if self.status.regime_redefined:
            if self.private_redefined_trigger is None:
                return self.private_trigger
            else:
                return self.private_redefined_trigger
        else:
            return self.private_trigger

    @trigger.setter
    def trigger(self, trig):
        if self.status.regime_redefined:
            self.private_redefined_trigger = trig
        else:
            self.private_trigger = trig

    @staticmethod
    def load_event(d):
        # Given a dictionary d, create and populate an ImagineEvent.
        if not ("name" in d and "trigger" in d):
            raise ValueError(f"Event configuration requires name and trigger. {d}")

        # If any of the fields for ImagineEventStatus are defined in the dictionary, put them in the status.
        origin = d.get('origin', 'config')
        crop_definition_locked = d.get('crop_definition_locked', True)
        deferred_to_regime = d.get('deferred_to_regime', False)
        deferred_to_regime_locked = d.get('deferred_to_regime_locked', True)
        regime_redefinable = d.get('regime_redefinable', False)
        regime_redefinable_locked = d.get('regime_redefinable_locked', True)

        ies = ImagineEventStatus(origin, crop_definition_locked, deferred_to_regime, deferred_to_regime_locked, regime_redefinable, regime_redefinable_locked)
#        trig = Trigger(d.trigger)
        ie = ImagineEvent(d.name, ies)
        ie.trigger = eval_condition_dictionary(d.trigger)

        return ie
