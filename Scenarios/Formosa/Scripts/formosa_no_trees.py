# Assumes this script is somewhere within the Imagine project.
# Include the Imagine folder on python's path so it finds the imagine package.
import pathlib
import sys
pathparts = pathlib.Path(__file__).parts
sys.path.append(str(pathlib.Path(*pathparts[:pathparts[:].index('Imagine')+1])))

from imagine.core import ImagineObject
from imagine.simulation.simulation_manager import SimulationManager
from imagine.crop.crop_manager import CropManager
from imagine.regime.regime_manager import RegimeManager
from imagine.simulation.sim_writer import SimWriter

# Set paddock size prior to loading scenario
im_ob = ImagineObject.get_instance()
im_ob.paddock_length = 500
im_ob.paddock_width = 500

scenario_folder = "Formosa"
im_ob.load_scenario(scenario_folder)

# Prepare pasture crop reference to modify in loop.
sim_mgr = SimulationManager.get_instance()
crop_mgr = CropManager.get_instance()
regime_mgr = RegimeManager.get_instance()
regime_mgr.remove_regime('Pine Regime')

# Run Sim
sim_mgr.simulate_in_months(1)
sim_mgr.simulations[0].sim_name = "Formosa No Trees"

# Write out all the sims to Excel.
sim_path = pathlib.Path(im_ob.folders["$Scenario"]) / "Sims" / "FormosaNoTrees.xlsx"
sim_writer = SimWriter(sim_mgr.simulations, sim_path)
sim_writer.write_sims_to_file()


