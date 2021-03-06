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
# Remove comments and protect the resulting source code with a ifdef.
function Remove-CommentsAndProtect ($file, $textInLine, [int] $nLines, $protectWithDefine)
{
    if (! $(Test-Path $file)) {
        throw "Unable to access file '$file' to add update."
    }

    # if it is done already, then the protect string is in it somewhere.
    $alreadyDone = Get-Content $file | ? {$_ -match $protectWithDefine}
    if (!$alreadyDone) {
        "" > temp.file
        $lineToClean = 0
        foreach ($l in $(Get-Content $file)) {
            if (! ($l -match $textInLine)) {
                $l >> temp.file
            } else {
                $lineToClean = $nLines
                "#ifdef $protectWithDefine" >> temp.file
            }
            if ($lineToClean -gt 0) {
                $l = $l -replace "//",""
                $l >> temp.file
                $lineToClean -= 1;
                if ($lineToClean -eq 0) {
                    "#endif" >> temp.file
                }
            }
        }
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
    # Becauyse algorithm isn't implicitly included in more modern versions of C++
    Add-Include $pythiaDir\src\SusyLesHouches.cc "<algorithm>"
    # As erf isn't defiend, and they provide something to replace it, however, they do not
    # make it easy to automatically use it (e.g. a define!!)
    Remove-CommentsAndProtect $pythiaDir\include\Pythia8\PhaseSpace.h "double erf" 3 EMULATE_ERF
    Remove-CommentsAndProtect $pythiaDir\include\Pythia8\SigmaTotal.h "double erf" 3 EMULATE_ERF

    # Add a dummy include file b.c. the C++ nuget packing mechanism has a bug in it
    "" > $pythiaDir/include/dummyfile.txt

    # Invoke MSBUILD...
    if (! $env:INCLUDE) {
        Set-VsCmd 2013
    }

    # Next, invoke the build(s).
    $pythiaDirFullName = $pythiaDir | gi | select -ExpandProperty FullName
    $buildDirFullName = $msbuildFile | gi | select -ExpandProperty DirectoryName
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Debug /p:PlatformToolset=v120
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Release /p:PlatformToolset=v120
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Debug /p:PlatformToolset=v110
    msbuild "$pythiaDir\$msbuildFilename" /p:PYTHIADIR=$pythiaDirFullName /p:PYTHIABUILDDIR=$buildDirFullName /p:Configuration=Release /p:PlatformToolset=v110
}

# Given an archive, uncompress it in the same place. Do it twice...
$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"
function Uncompress($path)
{
    if (-not $path.EndsWith(".tgz"))
    {
        throw "Only know how to uncompress .tar.gz files - $path"
    }

    $logFile = "$path-log.txt"
    $uncompressFlag = "$path-uncompressed"    
    if (-not (test-path $uncompressFlag)) {
      Write-Host "Uncompressing $path"
      "Uncompressing $path" | out-file -filepath $logFile -append

      $tarfileName = $path -replace "tgz","tar"
      $tarfileDir = Split-Path -Parent $path

      if (-not (test-path $tarfileName)) {        
        & "$SevenZipExe" e $path "-o$tarfileDir" | out-file -filepath $logFile -append
      }

      if (-not (test-path $tarfileName)) {
        throw "Could not find the tar file $tarfile after uncompressoing $path"
      }

      & "$SevenZipExe" x -y $tarfileName "-o$tarfileDir" | out-file -filepath $logfile -append

      $bogus = new-item $uncompressFlag -type file
    }
}

# Get the pythia version requested, and unpack it into the directory that we are looking at.
function Get-PythiaRelease ([string] $websiteVersion, [string] $unpackDir)
{
    # The directory where we expect everything to show up. We are dependent on no change happening
    # in how they distribute Pythia!!

    $unpackedDir = "$unpackDir\pythia$websiteVersion"

    # Download the raw file.

    $url = "http://home.thep.lu.se/~torbjorn/pythia8/pythia$websiteversion.tgz"
    $downloadedFile = "$unpackDir\pythia$websiteVersion.tgz"
    if (! $(Test-Path $downloadedFile)) {
        $client = new-object System.Net.WebClient
        $client.DownloadFile( $url, $downloadedFile )
        if (! $(Test-Path $downloadedFile)) {
            throw "Failed to download Pythia v$websiteversion"
        }
    }

    # Uncompress it

    Uncompress $downloadedFile

    # Make sure all went well

    if (! $(Test-Path $unpackedDir)) {
        throw "Failed to uncompress pythia for $websiteversion"
    }

    return $unpackedDir
}

# Downlaod and build a pythia release
function Get-PythiaBuiltRelease([string] $websiteVersion, [string] $buildDir, [string] $datafilesLocation)
{
    $pathToPythia = Get-PythiaRelease $websiteVersion $buildDir
    Invoke-PythiaBuild "$datafilesLocation/libPythia.vcxproj" $pathToPythia
}

Export-ModuleMember -Function Invoke-PythiaBuild,Get-PythiaRelease,Get-PythiaBuiltRelease

# Some command lines for testing.
# Setup: At the same level as this package create a directory called Pythia
#        Download into it the pythia 8186 release.
# Run from the PythiaPackaging root directory:
#
# Invoke-PythiaBuild ".\libPythia.vcxproj" "..\Pythia\pythia8186"
# Get-PythiaRelease 8185 ..\Pythia
# Get-PythiaBuiltRelease 8186 ..\Pythia .
