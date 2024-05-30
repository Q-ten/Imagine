# Imagine

Imagine is an agroforestry economic modelling tool. 
It focuses on the paddock scale and supports secondary tree crops 
set out in belts or borders. 

Simulation progresses on a monthly timescale, with the state of crops 
propagated from month-start to month-end, with a sophisticated event 
and triggering system.

Monthly gross margin is determined through income from crop 
production and costs incurred associated with triggered events.

Monte-carlo simulation is possible with many parameters set up to be 
sampled from probability distributions.

Configuration is achieved through text-based json5 files for intuitive
and expressive configuration with comments for in-place documentation 
and auditing.

Configuration options extend to easily importing data from Excel files
through the use of named ranges.

Simulation results can be output to a convenient Excel format.

Imagine was originally developed for Matlab. The Matlab files may be 
useful for future development and can be found in the Matlab Code folder. 

## Installation

Installation instructions can be found in INSTALL.

## Learning Imagine

This repository comes with a scenario that's ready to be run. The
Formosa scenario includes a README that is intended to introduce the 
reader to Imagine and to how scenarios are configured and run.

Tinker with the configuration options in the Formosa scenario to improve
your understanding and don't be afraid to jump into code to see 
where and how the configuration options are being used.

## License

Imagine is released under the Creative Commons, By Attribution, Non-Commercial, Share Alike license 
(CC BY-NC-SA 4.0.) Refer to License directory.

