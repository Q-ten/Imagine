from imagine.core import ImagineObject
import pathlib
from imagine.simulation.simulation_manager import SimulationManager
from imagine.crop.crop_manager import CropManager
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
pasture_crop = crop_mgr.get_crop('Pasture')

# Run Sims
suffixes = [""] + [str(n) for n in range(10, 100+1, 10)]
for suffix in suffixes:
    # Update the shelter settings function.
    pasture_crop.growth_model.propagation_parameters.shelter_settings_function = "get_formosa_settings" + suffix
    # sim_mgr appends new simulations to its list of sims.
    sim_mgr.simulate_in_months(1)
    sim_mgr.simulations[-1].sim_name = "Formosa" + suffix

# Write out all the sims to Excel.
sim_path = pathlib.Path(im_ob.folders["$Scenario"]) / "Sims" / "FormosaSensitivity.xlsx"
sim_writer = SimWriter(sim_mgr.simulations, sim_path)
sim_writer.write_sims_to_file()


