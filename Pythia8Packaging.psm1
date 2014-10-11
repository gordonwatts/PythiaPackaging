#
# Package for commands that can be used to get a pythia release and build
# it and publish it on nuget
#

# We need to set the VS command line variables so we can do some real work with
# the vs commands here.
function Set-VsCmd
{
    param(
        [parameter(Mandatory, HelpMessage="Enter VS version as 2010, 2012, or 2013")]
        [ValidateSet(2010,2012,2013)]
        [int]$version
    )
    $VS_VERSION = @{ 2010 = "10.0"; 2012 = "11.0"; 2013 = "12.0" }
    $targetDir = "c:\Program Files (x86)\Microsoft Visual Studio $($VS_VERSION[$version])\VC"
    if (!(Test-Path (Join-Path $targetDir "vcvarsall.bat"))) {
        "Error: Visual Studio $version not installed"
        return
    }
    pushd $targetDir
    cmd /c "vcvarsall.bat&set" |
    foreach {
      if ($_ -match "(.*?)=(.*)") {
        Set-Item -force -path "ENV:\$($matches[1])" -value "$($matches[2])"
      }
    }
    popd
    write-host "`nVisual Studio $version Command Prompt variables set." -ForegroundColor Yellow
}

#
# Add an include file reference to an existing source file. If it is already there,
# then do nothing.
#
function Add-Include ([string] $file, [string] $include)
{
    if (! $(Test-Path $file)) {
        throw "Unable to access file '$file' to add include."
    }
    $r = Get-Content $file | ? {$_ -match $include}
    if (! $r) {
      "#include $include" > temp.file
      Get-Content $file >> temp.file
      Copy-Item $file $file.old
      Copy-Item temp.file $file
    }
}

#
# Build pythia.
#  - The MSBuild file to be used
#  - Pythia must be fully downloaded and open in the directory given
#  - Results will be built as expected by the MSBUILD file.
#

function Invoke-PythiaBuild ([string] $msbuildFile, [string] $pythiaDir)
{
    # Make sure we have been given some clean arguments.

    if (! $(Test-Path $msbuildFile)) {
        throw "The msbuild file $msbuildFile was not found"
    }
    if (! $(Test-Path $pythiaDir)) {
        throw "The pythia directory $pythiaDir was not found"
    }
    if (! $(Test-Path "$pythiaDir/include")) {
        throw "While the pythia directory $pythiaDir was found, it doesn't seem to be right - missing the examples subdir..."
    }

    # Next, copy over the msbuild file

    Copy-Item $msbuildFile $pythiaDir
    $msbuildFilename = $msbuildFile | gi | select -expand name

    # Some of the source needs to be fixed up a little bit.
    Add-Include $pythiaDir\src\SusyLesHouches.cc "<algorithm>"

    # Invoke MSBUILD...
    if (! $env:INCLUDE) {
        Set-VsCmd 2013
    }

    # Next, invoke the build(s).
    $pythiaDirFullName = $pythiaDir | gi | select -ExpandProperty FullName
    $buildDirFullName = $msbuildFile | gi | select -ExpandProperty DirectoryName
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Debug
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Release
}

Export-ModuleMember -Function Invoke-PythiaBuild

