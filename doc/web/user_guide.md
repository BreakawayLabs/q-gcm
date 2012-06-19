# Q-GCM User Guide

This document outlines everything you need to know as a user of Q-GCM.

## Downloading Q-GCM

### Accessing Annexed Files

## Dependencies

## Compiling Q-GCM

Q-GCM is written in [Fortran 90](http://en.wikipedia.org/wiki/Fortran#Fortran_90) and distributed in source only form. As such, users must compile the model before running it.

By default Q-GCM uses the [`gfortran`](http://gcc.gnu.org/wiki/GFortran) compiler. Version 4.6.3 has been successfully tested, however any recent version should work fine.

To compile the model, run the following commands:

    cd src
    make

This will create the executable file `src/q-gcm`.

## Running Predefined Example Experiments

Q-GCM comes with a number of predefined example experiments.
These can be sued as a starting point for customising your own experiments.
It is advised to run a number of these examples to ensure the model is running correctly on your system.


## Experiment Directory Structure

## Running Custom Experiments

## Configuring Q-GCM

## Diagnostics

## Advanced Compiler Options