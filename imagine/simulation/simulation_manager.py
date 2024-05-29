from copy import deepcopy

from dotwiz import DotWiz

from imagine.core import ImagineObject  # Import relevant classes
from imagine.crop.crop_manager import CropManager
from imagine.regime.regime_manager import RegimeManager
from imagine.climate.climate_manager import ClimateManager
# from simulation_dialogue import SimulationDialogue  # Assuming this class exists
from imagine.simulation import Simulation
from imagine.simulation.sim_store import SimStore
from imagine.util.always import always


class SimulationManager:
    _instance = None

    def __init__(self):
        if always():
            raise RuntimeError('Call get_instance() instead')
        self.imagine_ob = None
        self.crop_mgr = None
        self.regime_mgr = None
        self.climate_mgr = None
        self.simulations = None
        self.folders = DotWiz()

    @classmethod
    def get_instance(cls):
        if not cls._instance:
            cls._instance = cls.__new__(cls)
            cls._instance._simulation_manager_constructor()
        return cls._instance

    def _simulation_manager_constructor(self):
        self.refresh_manager_pointers()
        # self.simulation_window = None
        self.simulations = []

    def refresh_manager_pointers(self):
        self.imagine_ob = ImagineObject.get_instance()
        self.crop_mgr = CropManager.get_instance()
        self.regime_mgr = RegimeManager.get_instance()
        self.climate_mgr = ClimateManager.get_instance()

    # def launch_simulation_dialogue(self):
    #     if self.simulation_window and self.simulation_window.is_valid():
    #         self.simulation_window.close()
    #     self.simulation_window = SimulationDialogue()

    def is_ready_for_simulation(self):
        return self.regime_mgr.is_ready_for_simulation() and self.climate_mgr.is_ready_for_simulation()

    def simulate_in_months(self, number_of_sims):
        # handles = self.simulation_window.get_handles() if self.simulation_window else {}
        # handles['isRunning'] = True
        # self.simulation_window.set_handles(handles)

        for sim_num in range(number_of_sims):
            # Your simulation logic goes here

            # Create the simulation
            # This creates inistialised sim_store along with prices
            sim = Simulation()


            # Create the rainfall data that will be used in the simulation and
            # fed to sim slowly as the simulation unfolds.
            sim.monthly_rainfall = self.climate_mgr.get_series('monthly rainfall')

            # Run the simulation
            for year in range(self.imagine_ob.simulation_length):

                # Set month index and day to first day of first month of the new year.
                sim.month_index = year * 12
                sim.year_index = year
                sim.month_day = 1

                # Get handles to the installedRegimes
                prim_reg = sim.current_primary_installed_regime
                sec_reg = sim.current_secondary_installed_regime

                for month in range(12):
                    # Update month index and day.
                    sim.month_index = year * 12 + month

                    # When sim.month_day is set to one, it will transfer
                    # plantedCrop states from the end of the previous
                    # month to the start of the new one.
                    sim.month_day = 1

                    # Install new regimes if possible.
                    if month == 0:

                        if prim_reg is None:
                            sim.install_regime_if_possible('primary')
                            prim_reg = sim.current_primary_installed_regime

                        if sec_reg is None:
                            sim.install_regime_if_possible('secondary')
                            sec_reg = sim.current_secondary_installed_regime

                    # Month Start

                    # Calculate the regime outputs and check if planting
                    # is possible in both regimes. Do secondary first
                    # as primary needs secondary area to calculate its
                    # own area.
                    if sec_reg is not None:
                        sec_reg.calculate_outputs()

                    if prim_reg is not None:
                        prim_reg.calculate_outputs()

                    if sec_reg is not None:
                        sec_reg.plant_if_possible()

                    if prim_reg is not None:
                        prim_reg.plant_if_possible()

                    # Set primary and secondary Planted Crops
                    prim_pc = sim.current_primary_planted_crop
                    sec_pc = sim.current_secondary_planted_crop

                    # Update crop outputs for month start
                    if prim_pc is not None:
                        prim_pc.calculate_outputs()

                    if sec_pc is not None:
                        sec_pc.calculate_outputs()

                    # Propagate state from month start to month end for each
                    # regime.
                    post_prop_ps = []
                    post_prop_ss = []

                    # Get the new states.
                    if prim_pc is not None:
                        post_prop_ps = prim_pc.propagate_state(sim)

                    if sec_pc is not None:
                        post_prop_ss = sec_pc.propagate_state(sim)

                    # Month End
                    sim.month_day = 30

                    # Set the new states once month end is set.
                    if prim_pc is not None:
                        prim_pc.state = post_prop_ps

                    if sec_pc is not None:
                        sec_pc.state = post_prop_ss

                    # Update crop outputs for month end.
                    if prim_pc is not None:
                        prim_pc.calculate_outputs()

                    if sec_pc is not None:
                        sec_pc.calculate_outputs()

                    # Check for the crop to be destroyed (final harvest) in both regimes.
                    prim_pc_destroyed = False
                    if prim_pc is not None:
                        prim_pc_destroyed = prim_pc.check_for_destruction(sim)

                    sec_pc_destroyed = False
                    if sec_pc is not None:
                        sec_pc_destroyed = sec_pc.check_for_destruction(sim)

                    # Test event triggers and process any events that occur for
                    # current crops in both regimes. Note that some of these
                    # events may be follow ons from a destructive harvest, so they
                    # are processed after we potentially trigger crop
                    # destruction. We still have a handle to the Planted Crop,
                    # so we can process events as we have not yet destroyed the
                    # crop.
                    if prim_pc is not None:
                        prim_pc.process_events(sim)

                    if sec_pc is not None:
                        sec_pc.process_events(sim)

                    # To destroy the crop, we set the Installed Regime's crop
                    # index to -1.
                    # If not destroyed, transfer state to next month.
                    # We pass the post propagation state because it
                    # should set the end month state back to that after
                    # it moves the current state to the next month.
                    if prim_pc_destroyed:
                        prim_pc.destroyed_month = sim.month_index
                    elif prim_pc is not None:
                        prim_pc.transfer_state_to_next_month(deepcopy(post_prop_ps))

                    if sec_pc_destroyed:
                        sec_pc.destroyed_month = sim.month_index
                    elif sec_pc is not None:
                        sec_pc.transfer_state_to_next_month(deepcopy(post_prop_ss))

                # End months

                # End regime if appropriate.
                if prim_reg is not None:
                    if prim_reg.final_month == sim.month_index:
                        sim.primary_regime_index = -1

                if sec_reg is not None:
                    if sec_reg.final_month == sim.month_index:
                        sim.secondary_regime_index = -1

            # End years and so simulation
            self.simulations.append(sim)

        # End number of sims.

        # Finalizing simulation
        self._finalize_simulation()

    def _finalize_simulation(self):
        # Finalisation logic if needed.
        # handles = self.simulation_window.get_handles() if self.simulation_window else {}
        # handles['isRunning'] = False
        # self.simulation_window.set_handles(handles)
        #
        # # Additional logic if needed
        #
        # # Clean up
        # self.simulation_window = None
        #

        # Display or save simulation results if needed
        print("Simulation completed. Simulations:", self.simulations)
