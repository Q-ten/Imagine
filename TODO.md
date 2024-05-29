# Ideas for future development

## Scenario version control

It would be nice to have a complete snapshot of the code + data inputs that 
are used to generate a simulation. 

Further, if we can be sure that the code + data have not changed, it would be 
nice to extend existing simulations rather than replace them.

One way I see this can be done is by using git to commit the Scenario folder
(and potentially the global Resources folder) before each simulation, then 
record the identity of the commit within the sim.

For any given sim, we could then checkout the folder structure as it was 
when the simulation was run. We could run more sims, or audit the data for those 
sims.

We might want commits on the source code, the global resources folder, and
the scenario folder. These three commit points would characterise the state
of the scenario when it was simulated.

## Code clean up

In the conversion from Matlab to Python, whole classes got translated before 
really integrating that class into the new python framework. So there 
are lots of functions in the python version that came from Matlab, but 
are not being used.

## TODO cleanup

Dozens of 'TODO's are currently sitting in the code base. Either do them or cut them.

## Additional Porting

Some of the classes used in the original Matlab implementation are yet 
to be fully ported to the Python version. These will probably be done on an
as-needed basis.

## UI or web framework

It would be great to provide access to Imagine through a UI like Matlab did.
It might make the most sense to provide a web-based UI. This would be a big undertaking though.

## Testing

Implementing tests in Imagine will be a really big undertaking. As it stands,
testing is done by running scenarios, checking results, and auditing the 
calculations via the debugger. This could be improved. A series of automated tests may provide peace of 
mind for the accuracy of the calculations.

## Documentation

Imagine is developed as a framework intended to be extended. There would be 
value in providing documentation on the core API along with examples of how 
to extend (work through of a new growth model, for example.)
