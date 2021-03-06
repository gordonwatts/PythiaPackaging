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

The nuget package can be found here: https://www.nuget.org/packages/Pythia8/

A debug database (pdb) is included for all builds. However, source code is not part of the nuget package,
nor has it been placed on any internet symbol servers. For now, if you want to step in, you should download
the offical source tar ball and redirect visual studio when it asks you to manually find the source file.
Make sure you match the nuget version to the tarball or you'll get some odd results. And remember a release
build is fully optimized, so...

Building a new set of NuGet packages
====================================

Prereq:

1. Visual Studio 2013 and 2012 installed (scripts build both versions)
2. CoApp tools (https://github.com/coapp/coapp.powershell). At the time this was written (Oct 2014) we had to use the version in github. Extract, and build the powershell tools version, then run it in Powershell in order to get the Write-NugetPackage command.

Steps:

1. Download this package to your machine.
2. Using powershell put yourself in this directory.
3. PS> import-module ./Pythia8Packaging.psm1
4. PS> Get-PythiaBuiltRelease 8186 ..\Pythia .
5. Edit the Pythia8.autopkg file to make sure the proper version is listed.
6. PS> Write-NugetPackage Pythia8.autopkg
7. PS> nuget push Pythia8.*.nupkg
8. On the nuget website unpublish the overlay packages to prevent confusion from the nuget search interface in Visual Studio.

Notes
=====

- If there is a version that you'd like in nuget that isn't there feel free to enter an issue in the github project
- If there is an issue with the generator itself, please use more normal means to get help! I'm only a very simple user! Start with the Pythia home page and documentation: http://home.thep.lu.se/~torbjorn/Pythia.html
