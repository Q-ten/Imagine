from imagine.events.imagine_event import ImagineEvent


class RegimeEventTrigger:

    def __init__(self, event_name, trigger, redefinable):

        self._private_trigger = trigger
        self.event_name = event_name
        self.regime_redefinable = redefinable
        self._private_redefined_trigger = None
        self._private_regime_redefined = False

    @property
    def trigger(self):
        if self.regime_redefined:
            return self._private_redefined_trigger
        else:
            return self._private_trigger

    @property
    def regime_redefined(self):
        return self._private_regime_redefined

    @regime_redefined.setter
    def regime_redefined(self, redefined_flag):
        if self.regime_redefinable:
            self._private_regime_redefined = redefined_flag

    @property
    def name(self):
        return self.event_name

    @trigger.setter
    def trigger(self, t):
        if self.regime_redefined:
            self._private_redefined_trigger = t
        else:
            self._private_trigger = t

    def set_private_trigger(self, private_trigger):
        self._private_trigger = private_trigger

    def set_private_redefined_trigger(self, private_redefined_trigger):
        self._private_redefined_trigger = private_redefined_trigger

    def convert_to_event(self, status):
        ev = ImagineEvent(self.name, status)
        if status.regime_redefinable:
            ev.status.regime_redefined = False
            ev.trigger = self._private_trigger
            ev.status.regime_redefined = True
            ev.trigger = self._private_redefined_trigger
            ev.status.regime_redefined = self.regime_redefined
        else:
            ev.trigger = self.trigger
        return ev

    def convert_from_event(self, ev):
        self.event_name = ev.name
        self.regime_redefinable = ev.status.regime_redefinable
        if self.regime_redefinable:
            self.regime_redefined = ev.status.regime_redefined
            ev.status.regime_redefined = False
            self._private_trigger = ev.trigger
            ev.status.regime_redefined = True
            self._private_redefined_trigger = ev.trigger
            ev.status.regime_redefined = self.regime_redefined
        else:
            self._private_trigger = ev.trigger

    def crop_name_has_changed(self, previous_name, new_name):
        if self._private_trigger is not None:
            self._private_trigger.crop_name_has_changed(previous_name, new_name)
        if self._private_redefined_trigger is not None:
            self._private_redefined_trigger.crop_name_has_changed(previous_name, new_name)
