import numpy as np

from imagine.events.imagine_condition import ImagineCondition


class TimeIndexedCondition(ImagineCondition):
    index_choices = ['Month', 'Year']

    def __init__(self, index_type, indices, shorthand=""):
        super().__init__(shorthand)
        if index_type in self.index_choices:
            self.indexType = index_type
        else:
            raise ValueError(f"Index type must be a string and either 'Month' or 'Year': {index_type}")

        if isinstance(indices, int):
            self.indices = np.array([indices])
        elif isinstance(indices, range):
            self.indices = np.array(indices)
        elif not isinstance(indices, list):
            raise ValueError(f"Indices provided to TimeIndexedCondition must be a single int or a list of ints: {indices}")
        else:
            self.indices = np.array(indices)


    @property
    def condition_type(self):
        return 'Time Index Based'

    """
    This property is not needed in the python version.
    @property
    def figureName(self):
        return 'conditionPanel_TimeIndexBased.fig'
    """

    @property
    def handles_field(self):
        return 'TimeIndexBasedHandles'

    def crop_name_has_changed(self, previousName, newName):
        pass

    def get_longhand(self):
        switcher = {
            'Year': 'Year Index is ',
            'Month': 'Month Index is ',
        }
        lh = switcher.get(self.indexType, 'Invalid index type')
        if len(self.indices) == 0:
            lh += '?'
            return lh
        indices = np.array(sorted(set(self.indices))) + 1 # Add 1 here to shift from 0-indexing to 1-indexing.
        spacing = len(set([j-i for i, j in zip(indices[:-1], indices[1:])]))
        if spacing == 0:
            # One element
            lh += str(indices)
        elif spacing == 1:
            # Spacing is uniform
            if len(set(indices)) >= 2:
                # Normal uniform
                lh += f"{indices[0]}, {indices[1]}, ..., {indices[-1]}"
            else:
                # 2 elements
                lh += f"{indices[0]} or {indices[1]}"
        else:
            # Spacing is non-uniform
            lh += f"one of {indices}"
        return lh

    """ 
    These methods are not needed in the python version as they relate to setup and retrieval of the condition from a matlab gui.
    def loadCondition(self, panel):
        handles = panel.children
        if not hasattr(handles, self.handlesField):
            raise ValueError('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.')
        newControls = getattr(handles, self.handlesField)
        newControls.popupmenuIndexType.values = self.indexChoices
        newControls.popupmenuIndexType.value = self.indexChoices.index(self.indexType)
        newControls.editIndices.value = str(self.indices)

    def saveCondition(self, panel):
        handles = panel.children
        if not hasattr(handles, self.handlesField):
            raise ValueError('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.')
        newControls = getattr(handles, self.handlesField)
        self.indexType = newControls.popupmenuIndexType.value
        self.indices = list(map(int, newControls.editIndices.value.split(',')))
    """

    def is_triggered(self, sim, planted_crop):#month_index, year_index):

        if self.indexType == 'Year':
            return any(self.indices == sim.year_index)

        if self.indexType == 'Month':
            return any(self.indices == sim.month_index)

        return False


    """
    This method is not needed in the python version.
    def setupFromOldStructure(self, s):
        self.indexType = s['string1'][s['value1']]
        self.indices = list(map(int, s['string2'].split(','))))
    """

    def is_valid(self):
        if not super().isValid():
            return False
        if not isinstance(self.indexType, str):
            return False
        if not isinstance(self.indices, list) or len(self.indices) < 1:
            return False
        if not any(self.indexType == indexChoice for indexChoice in self.indexChoices):
            return False
        if not all(index > 0 for index in self.indices):
            return False
        return True
