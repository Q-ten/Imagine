# Installation

## Get Python
Imagine has been developed with python 3.11. You may well already have python installed, but 
it's a good idea to install a python environment just for Imagine 
if you can.

There's no 'correct' way to install python or to manage python environments.
Several popular python environment managers exist including:

- [Anaconda](https://www.anaconda.com)
  - Installer download (https://www.anaconda.com/download/success)
- [pipenv](https://pipenv.pypa.io/)
- [venv](https://docs.python.org/3/library/venv.html)

For those new to using python or python environments, Anaconda has 
the advantage of providing Anaconda Navigator, a GUI tool 
that can be used to install/setup python environments. Anaconda is a 
commercial entity with a range of confusing paid-for offerings, but 
(at time of writing) you don't need any paid component just to 
install environments.

## Install Git

Git is a version-control tool for managing files in repositories. 
With it, you can download repositories, commit new work, switch versions, etc.
As Imagine is hosted on github.com as a git repository it's good to have
git installed. You can install git following instructions here:

https://github.com/git-guides/install-git

## Get Imagine

Once git is installed, getting Imagine is simple. Open a command 
prompt in the directory where you want Imagine installed and run:

    git clone https://github.com/Q-ten/Imagine.git

## Activate your python environment

If you have created a python environment just for Imagine, you may need to 
activate it before using it. How you do this depends on your environment
manager. If you're using a python environment manager you need to 
activate it before installing the required packages in the next step and 
whenever you're running Imagine. 

Here is the command for Anaconda, assuming you've created an 
environment called 'imagine':

    conda activate imagine

## Installing required python packages

Navigate to the imagine folder:

    cd Imagine
    cd imagine

The uppercase Imagine folder contains everything related to Imagine.
The lowercase imagine folder inside Imagine contains the python package. 
The file requirements.txt lists the packages required for imagine.
We use python's pip tool to install them. 

    pip install -r requirements.txt

## Running a Scenario

Run a python script by passing the name of the script file 
to the python command:

    python my_script_file.py

Imagine comes with the Formosa Scenario to get you started. 
To run the example, navigate to its Scripts folder and run 
one of the scripts. From the Imagine folder you can do:

    cd Scenarios/Formosa/Scripts
    python formosa_no_trees.py

More information can be found in the README file in the Formosa 
folder.
