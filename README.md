PythiaPackaging
===============

The Pythia8 MC Generator home page can be found here: http://home.thep.lu.se/~torbjorn/Pythia.html

- Usage
- Packaging up a new version of Pythia

Using Pythia8 In a C++ Program
==============================

1. Create a new C++ program. Currently Visaul Studio 2012 and 2013 are supported, 32-bit, release or debug.
2. Using the nuget interface, add the "Pythia8" package to your project. You can use the command line if you want a specific version of Pythia8.
3. Code as you would normally code!
4. In the project "Debug" settings, add the environment variable definition: "PYTHIA8DATA=$(TargetDir)\Pythia8Data"
5. Run!

Notes
=====

- If there is a version that you'd like in nuget that isn't there feel free to enter an issue in the github project
- If there is an issue with the generator itself, please use more normal means to get help! I'm only a very simple user! Start with the Pythia home page and documentation: http://home.thep.lu.se/~torbjorn/Pythia.html
