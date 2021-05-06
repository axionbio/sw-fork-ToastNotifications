<#

.SYNOPSIS
This is a script to increment or set a new ToastNotifications build version which will be added to the next build.

.DESCRIPTION
If no arguments are given uses whatever version is set in the default project (Src/ToastNotifications)

If "-bump" is given as the argument the script will get the current build number and increase the revision by 1.

If "-version" followed by a numerical version is given as the argument, the following happens:

If argument is "x", new version is x.0.0.0.
If argument is "x.y", new version is x.y.0.0.
If argument is "x.y.z", new version is x.y.z.0.
If argument is "x.y.z.w", new version is x.y.z.w.

"-Bump" and "-Version" cannot be used together.

If optional "-Push" argument is given the script will commit and push new changes (version bump)
#>

# ---------------------------------------------------------------
# Parameters
# -version followed by a version # or just a version #. (default)
# -bump to incrememnt the version by 1
# -push to push committed changes to origin
# ----------------------------------------------------------------
[CmdletBinding(DefaultParameterSetName="Version")]
param
(
    [Parameter(Mandatory=$false, ParameterSetName="Version", Position=0)]
    [string]
    $Version=$null,

    [Parameter(Mandatory=$false, ParameterSetName="Bump", Position=0)]
    [switch]
    $Bump=$false,

    [Parameter(Mandatory=$false)]
    [switch]
    $Push=$false
)

# ---------------------------------------------------------------
# Global variables
# ----------------------------------------------------------------
#Set defaults
$Global:NewVersion = $null
$Global:Major = [int]0
$Global:Minor = [int]0
$Global:Build = [int]0
$Global:Revision = [int]0

$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE"
$Global:Projects = "ToastNotifications", "ToastNotifications.Messages"

# -----------------------------------------------------------------
# CheckForDirtyFiles
# Checks repo for dirty files or some other git voodoo
# -----------------------------------------------------------------
function CheckForDirtyFiles
{
    Write-Verbose "Checking for dirty files`n"

    $GitCleanResult = (git status --porcelain)
    Write-Verbose "git status result is $GitCleanResult"

    if ($GitCleanResult)
    {
        Write-Host "`nYou have some dirty files. Consider a 'git reset --hard HEAD' or a 'git clean -dfx' before revving the version`n" -ForegroundColor Red
        exit
    }

    $CurrentBranch = (git branch --show-current)

    if ($CurrentBranch -ne "main")
    {
        Write-Host "Current branch is not main!" -ForegroundColor Red
        exit
    }

    Write-Verbose "Your repository is clean! Proceeding to getting your versions.`n"
    return
}

# -----------------------------------------------------------------
# VerifyInput
# Funtion to validate command line argument
# -----------------------------------------------------------------
function VerifyInput
{
    if (!$Version -and !$Bump)
    {
        Write-Host "Argument list is empty - not changing version"
        return
    }
    if ($Bump)
    {
        # "Bump and go to SetVersion"
        return
    }

    $fVersionInput = $Version.ToString().Split(".")

    # Check Length <= 4
    if ($fVersionInput.Length -gt 4)
    {
        "`nToo many numbers. Invalid version."
        exit
    }
    # Check for Valid digits
    for ($i = 0;$i -lt $fVersionInput.Length; $i++)
    {
        if ($fVersionInput[$i] -notmatch "\d+")
        {
            "Invaild input ($fVersionInput)"
            "'Version Component is not a number"
            exit
        }
    }
    # If you're here: you have 1 -> 4 digits
    $Global:Major    = If ($fVersionInput[0]) { $fVersionInput[0] } Else {"0"}
    $Global:Minor    = If ($fVersionInput[1]) { $fVersionInput[1] } Else {"0"}
    $Global:Build    = If ($fVersionInput[2]) { $fVersionInput[2] } Else {"0"}
    $Global:Revision = If ($fVersionInput[3]) { $fVersionInput[3] } Else {"0"}

    Write-Verbose "Major = $Global:Major"
    Write-Verbose "Minor = $Global:Minor"
    Write-Verbose "Build = $Global:Build"
    Write-Verbose "Revision = $Global:Revision"
}

# -----------------------------------------------------------------
# SetVersion
# Funtion to update the new version in specific files
# -----------------------------------------------------------------
function SetVersion
{
    if (!$Version -and !$Bump)
    {
        return
    }

    # If Bumping
    if ($Bump)
    {
        # Get-Content from the first project
        $fSoftwareVersionFile = "../Src/" + $Global:Projects[0] + "/" + $Global:Projects[0] + ".csproj"

        # Search though file For Version Number
        $Search = Select-String -Path $fSoftwareVersionFile -Pattern "AssemblyVersion" | ForEach-Object{$_.Line}
        $match = $Search -match '\d+\.\d+\.\d+\.\d+'
        $fDigit = $Matches[0]

        # Set $Major, $Minor, $Build to numbers from files
        $Global:Major = $fDigit.split(".")[0]
        $Global:Minor = $fDigit.split(".")[1]
        $Global:Build = $fDigit.split(".")[2]
        $Global:Revision = [int]$fDigit.split(".")[3] + [int]1

       #"Bump status = $Global:Shouldbump and revision = $Global:Revision"
       "`nCurrent version is $Global:Major.$Global:Minor.$Global:Build.$([int]$fDigit.split(".")[3])."

       Write-Verbose "Bump status = $Bump and new revision = $Global:Revision."
    }

    $Global:NewVersion = "$Global:Major.$Global:Minor.$Global:Build.$Global:Revision"

    Write-Host "Setting version " + $Global:NewVersion

    $versionRegexp = "(\d+\.\d+\.\d+\.\d+)"

    foreach ($project in $Global:Projects) {
       $assemblyInfoFile = "../Src/"+$project+"/$project.csproj"
       (Get-Content $assemblyInfoFile) -replace $versionRegexp, $Global:NewVersion | Set-Content $assemblyInfoFile
    }
}

# -----------------------------------------------------------------
# CommitNewVersion
# Function to commit and push version changes
# -----------------------------------------------------------------
function CommitNewVersion
{
    # Adding and commiting
    git add -u
    git commit -m "Bump to $Global:NewVersion"

    if($Push)
    {
        "Pushing up to origin."
        git push
    }
    else
    {
        "
        ==================================================================
        == IMPORTANT! YOU ABSOLUTELY MUST PUSH THIS TO ORIGIN!
        ==================================================================
        Did you hear that?
        I've committed the version bump, but only locally. You still need to:
                $ git push origin
        Or do it however you'd like to make this happen for real.
        If you don't, this version bump is only for YOU and not for everyone else.`n`n
        "
        return
    }
}

function BuildAndPackage
{
    $solution = "../Src/ToastNotifications.sln"

    devenv $solution /rebuild Release

    foreach ($project in $Global:Projects) {
        $csprojFile = "../Src/"+$project+"/"+$project+".csproj"
        dotnet pack $csprojFile --configuration Release
    }
}

# Check that everything is checked-in
CheckForDirtyFiles

# Verify argument given (and bump if argument is 'bump')
VerifyInput

# Write out new version (bump or full)
SetVersion

# Build and package
BuildAndPackage


