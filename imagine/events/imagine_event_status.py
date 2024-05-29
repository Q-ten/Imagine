"""
% This class contains the 6 parameters that govern how and where a trigger
% may be set for an event. The class takes care of restricting access to
% parameters if the Locked version is set to true.
"""


class ImagineEventStatus:
    def __init__(self, origin, crop_definition_locked, deferred_to_regime, deferred_to_regime_locked, regime_redefinable, regime_redefinable_locked):
        if not isinstance(origin, str):
            raise ValueError("First argument to ImagineEventStatus must be a string.")
        
        self.origin = origin
        self.crop_definition_locked = bool(crop_definition_locked)
        self._deferred_to_regime = bool(deferred_to_regime)
        self.deferred_to_regime_locked = bool(deferred_to_regime_locked)
        self._regime_redefinable = bool(regime_redefinable)
        self.regime_redefinable_locked = bool(regime_redefinable_locked)
        self._regime_redefined = False

    @property
    def deferred_to_regime(self):
        return self._deferred_to_regime

    @deferred_to_regime.setter
    def deferred_to_regime(self, value):
        if not isinstance(value, (int, bool)):
            raise ValueError("Cannot set deferred_to_regime to non-numeric value.")
        
        if self.deferred_to_regime_locked:
            print("Attempt made to set locked deferred_to_regime status in event.")
        else:
            self._deferred_to_regime = bool(value)

    @property
    def regime_redefinable(self):
        return self._regime_redefinable

    @regime_redefinable.setter
    def regime_redefinable(self, value):
        if not isinstance(value, (int, bool)):
            raise ValueError("Cannot set regime_redefinable to non-numeric value.")
        
        if self.regime_redefinable_locked:
            print("Attempt made to set locked regime_redefinable status in event.")
        else:
            self._regime_redefinable = bool(value)

    @property
    def regime_redefined(self):
        return self._regime_redefined

    @regime_redefined.setter
    def regime_redefined(self, value):
        if not isinstance(value, (int, bool)):
            raise ValueError("Cannot set regime_redefined to non-numeric value.")
        
        if value:
            if self._regime_redefinable:
                self._regime_redefined = bool(value)
            else:
                print("Tried to set event status to regime_redefined, but it is not regime redefinable.")
        else:
            self._regime_redefined = bool(value)
