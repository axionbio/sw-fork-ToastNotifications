# Axion Fork of ToastNotifications

The #[original project](https://github.com/rafallopatka/ToastNotifications) have
not been updated in a while and we had trouble getting our PRs approved and
merged.  In light of this we have decided to create our own fork of the
ToastNotifications repo for all our fixes.

## Branch Names

Following the #[github  convention](https://github.com/github/renaming) the
default branch is named `main`.  This is the branch that should be used to build
nuget packages for AxIS Z and other Axion applications.

## Build Process

- Make sure all the desired changes are merged into the `main` branch
- Checkout `main`
- Open the `powershell` console and change the current directory to `Build`
- Execute`generate-nuget.ps1` script to generate nuget packages
  - Specify `-Version` followed by version string to set the specified version
    (Ex: `generate-nuget.ps1 -Version "2.5.5"`)
  - Specify `-Bump` to increment revision by 1.  Ex:  `generate-nuget.ps1 -Bump`
    will change the version from `2.5.4.0` to `2.5.4.1`
  - Calling `generate-nuget.ps1` without any arguments will not update the version
- Copy output `.nupkg` files to `Build\NugetPackages` folder in the `axis` repo.
- Open a PR in `axis` to update the packages in `axis` default branch
