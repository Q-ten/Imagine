# Formosa Scenario

The Formosa Scenario was one of the scenarios developed in the 
original Matlab implementation and serves as a good example for how Imagine has 
been ported to Python. 

The Formosa scenario models pasture with sheep and on the border, 
pine. The sheep may benefit from the pine and there may be amenity 
value from the presence of trees on the property. The scenario as 
modelled in the Matlab version of Imagine is detailed in

	Resources/Modelling of agroforestry costs and benefits final November 2018.pdf

Follow through the Formosa Scenario to understand how Imagine 
works and how to develop your own scenarios.

You can see the code for running a Formosa scenario in either of 
these files. The no-trees version is simpler.

	Scenarios/Formosa/Scripts/formosa_no_trees.py
	Scenarios/Formosa/Scripts/formosa_sensitivity_run.py

These files are Python script files and can be run directly. There 
is no 'right' way to run a python script, but one way is to run it 
from the command line. Navigate to their folder and run:

	python formosa_no_trees.py

If python3 is not the default python version you may need to run 

	python3 formosa_no_trees.py

## Scenario Folder

A Scenario is represented by a sub-folder within the Scenarios 
folder. In this case, it's simply called 'Formosa.'

Imagine expects to have a Scenario. To run any scenario, it is 
loaded by providing the name of the Scenario folder:

	im_ob.load_scenario('Formosa')

Within a scenario folder, you may find the following sub-folders: 
- Climate
- Crops
- Regimes
- Resources
- Scripts
- Sims


### JSON5 configuration

The Climate, Crops, and Regimes folders contain .json5 
scenario configuration files. 

json5 is a file format like json, but allows the inclusion of 
comments which means you can document what you are configuring in 
the file.

The file format allows for clear configuration of key:value pairs. 
The user can assign to a name numbers, strings (i.e. 
text), lists of things, or collections of key:value pairs called 
'objects'.

The file format is relatively intuitive, but many 
resources exist online to better understand possible formats.

One particularly useful tool is known as a validator. A validator 
lets you paste in text for a particular format and check if it conforms to the expected format. 
If there are problems, it will highlight them for you to fix. 

The json5 files used in Imagine will only work if they follow the 
correct format. Use a validator tool to check for correct format and 
find problems.

One such tool can be found here: [CodeBeautify JSON5 Validator](https://codebeautify.org/json5-validator)

### Resources

Within a Scenario folder, the Resources sub-folder is a convenient 
place to locate anything that could be used as a resource for the scenario.
Resource files may be referred to from other files.

In the Formosa scenario, the Formosa.xlsx file is a convenient data series
store. You will see the climate and crop configuration files include 
references to the Formosa.xlsx file and can import data from named 
ranges. 

The pdf file details how Formosa and other similar scenarios were 
modelled in the original Matlab version.

The get_formosa_settings.py file provides functions used to configure 
shelter benefits for Formosa.

> #### Top-Level Resources
>
>There is also a convenience Resources folder one level higher that is intended for 
resources that would be more broadly relevant than a single Scenario.

### Scripts

The Scripts sub-folder is a convenient location to place python script 
files that could be used to run Imagine. Other scripts could be located 
here too. The folder is just a convenience. Though not technically a script, the get_formosa_settings.py file 
might reasonably be relocated here.

### Sims

The Sims folder a convenience folder for simulation output files.
Outputs are in Excel format. 

The name of the Excel file is set in the script file that runs the 
simulation. It's not restricted to the Sims folder, but is convenient.

Imagine can be configured to run multiple simulations of the same Scenario.
When saving output to an Excel file, each worksheet represents the output 
of a single simulation. Multiple simulations means multiple worksheets.

The formosa_sensitivity_run.py script is an example of performing 
multiple simulations while varying a single aspect of the scenario. 
As seen in the script it is also possible to set a meaningful name for each 
simulation, which will be used as the worksheet name in Excel. If a sim name is not 
set, simulations are named Sim1, Sim2, etc.

>#### Adding Stochasiticy for Monte-Carlo simulation
>
>The Formosa scenario is an example of a scenario with no stochasticity. 
That is, no variability in the input data. However, Imagine is also 
> designed to work with uncertain data. Many parameters in Imagine can 
> be setup as probability distributions. During a simulation, such probability
> distributions are sampled accordingly.
> 
> Multiple simulations can be performed to build up a representative 
> sample of the outputs. The multiple sims exported to Excel could then
> be processed further to develop overall statistics.

## Regimes

Imagine is a single paddock simulation tool, particularly suited for 
agroforestry simulation. A Regime represents the landuse for a 
particular region of the paddock over a number of years.

The regions of the paddock are referred to as Primary and Secondary.
Secondary regime regions are specific regions set up for a secondary 
crop, like pine. This region can be configured a series of belts 
within the paddock, or borders on the edge of the paddock, or both.

The primary region is everywhere else.

As well as defining primary and secondary regions, regimes define when
certain crops will be planted/removed. 

The primary regime is required. The secondary regime is optional.

Currently, the primary regime is an Annual Regime, which supports 
annual crops and pastures. The secondary regime is a Belt Regime which 
supports tree crops. These two types could potentially be modified 
or extended at some point. An example might be a primary regime for block tree crops.

The different types of regime require different configuration. 
Look at the pasture_regime.json5 and pine_regime.json5 files.

A small set of common regime parameters are set at the top of each file
then the regime-type-specific parameters are set out below.

## Crops

Crop configurations in Imagine have a set of common parameters, and then
a set of crop-type-specific parameters. 

### Growth Model
The crop's GrowthModel determines how the crop grows during the simulation and type will determine the such but most of the 
configuration is done within its GrowthModel. Various growth model 
types have been implemented. (And maybe more in future.)

A growth model is responsible for simulating the progress of a crop 
through a simulation.

It does the following:
- Maintains an internal 'state' of the crop.
- Propagates the state of the crop from the start of a month to the end of a month.
- Determines what products a crop produces. Products get sold at configured prices and generate income.
- Determines certain 'outputs' of a crop. These are quantities of interest, but do not generate income.
  - Outputs are sometimes used as the basis for costs.
- Responds to certain 'events'. GrowthModels typically define a set of 
events that require the state to be processed. Examples include 
planting and harvesting events, but other events may be defined 
depending on the growth model.

One of the crop configuration parameters common to all crop is the 
growth model name. Then the specific parameters for the chosen 
growth model are included.

### Price Models

A crop configuration also defines Price Models. It needs price models 
for the products it produces and for costs that it incurs at certain events.
Events that incur costs but are not part of a growth model's intrinsic events
can be configured as 'Financial Events.'

Price models are defined using 'trends'. The trend in a price model 
is used to determine what the price is in a particular year. More on trends below. 

Products are produced when a growth model event occurs or during monthly propagation. 
The matching product price model is used to determine the income from that product.
Costs are incurred when a matching growth model event occurs. 
Financial Events occur when they are triggered, as per their configured trigger.

The fields for defining Product Price Models, Cost Price Models, and Financial Events are summarised below:

|             | Product Price Model  | Cost Price Model | Financial Event          |
|-------------|----------------------|------------------|--------------------------|
| name        | Required             | Required         | Required (as event name) |
| units       | Required             | Required         | Required                 |
| event_name  | Optional. See below. | Required         | N/A                      |
| event_names | Optional. See below. | N/A              | N/A                      |
| trend       | Required             | Required         | Required                 |
| trigger     | N/A                  | N/A              | Required                 |

Price models use units to determine the total value to include when accounting 
income/costs.

When products are produced, they are given as a quantity plus a unit. For example, 
'200 tonnes of wheat'. The corresponding price model would include units as '$ / tonne of wheat'.
The units of products are matched to their price model.

Similarly, for cost price models, the cost is defined in terms of dollars per \[unit]. 
The units available to define costs include:
- products produced at the time the cost is incurred
- crop outputs
- regime outputs

Some examples:

- $10 / tonne of wheat  (cost related to production)
- $20 / head of sheep sheared (cost from a hypothetical shearing event)
- $55 / ha of wheat  (cost related to regime output)
- $7 / m of belt-crop interface length (cost related to a regime output)

Product price models can be defined with one, multiple, or zero event names.
Usually, you'd specify a single event name. But sometimes, different events 
might produce the same product, so you'd include multiple event names.
Occasionally, you may want to define a universal price model for the given units.
Particular events may then be 'overridden' by also providing price 
models for those events.


| Product Price Model<br/>Event Name Field | Data type       | Use                                                            |
|------------------------------------------|-----------------|----------------------------------------------------------------|
| event_name                               | string          | Price model applies to products from the given event.          |
| event_names                              | list of strings | Price model applies to products from any of the listed events. |
| [not given]                              | N/A             | Price model applies to products when no other match is found.  |


## Climate Models

Climate models provide simulation-wide climate data for growth 
models to consume. It is typical to import climate data from a more 
convenient resource such as an Excel file.

>Currently, only 'monthly rainfall' is required for the growth models 
implemented in Imagine. This could be extended in future for more 
sophisticated models. However, many excellent external climate and growth 
models exist. The option often used is to generate climate data 
externally as necessary, potentially run sophisticated growth models 
externally with this data and to import the results for a particular crop.
>
>This may be favourable when the user wishes to model growth with 
sophisticated external models, and use Imagine for subsequent analysis, 
such as for monte-carlo economic analysis where probability distributions
are set up to simulate economic uncertainty.

## Trends

Trends are used in Imagine to represent a data series changing over time.

Trends are used to define prices, but may also be used elsewhere, such as 
in configuring rainfall or growth models parameters.

Trends are configured to define probability distributions. During a simulation 
the distributions are sampled to generate a time series for that simulation.
(Currently only the Gaussian distribution is supported, but this could be 
extended in future.)

While trends provide a simple way to inject stochasticity into Imagine,
they are also very simple to configure as non-stochastic

Trends define the mean and standard deviation of distributions from which they'll sample.
These are independently defined. Each year we need a way to determine the 
mean of the probability distribution and the standard deviation.

As implemented, there are two ways to do this. With a polynomial function and
with yearly data.

The polynomial is defined with the coefficients of the polynomial.
This is makes it very easy to define a constant; just one number. But then it's 
also quite simple to define an upward or downward linear trend (2 numbers) or perhaps 
an accelerating trend (3 numbers).

Yearly data is simply a list of numbers to use in sequence. If the length of the 
yearly data is less than the number of years, it repeats from the beginning.

Perhaps confusingly the 'mean' series is referred to as the 'trend' and
the 'standard deviation' series is referred to as the 'var' (for variability).
Note that **var does not mean variance**.

So when defining a trend, we set the 'type' (Polynomial or Yearly) for both trend and var.
And we set the 'data' for both trend and var.
The data is interpreted as polynomial coefficients or yearly data accordingly.

Here is an example trend configuration for a non-stochastic constant value of 100 each year:

      trend: {
        trend_type: "Polynomial", var_type: "Polynomial",
        trend_data: [100],
        var_data: [0]
      },

