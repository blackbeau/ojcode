
$script:NIpkgExeName="nipkg.exe"
$script:PackageSource = "https://www.ni.com"
$script:ProviderName="nipkg"

function Get-PackageProviderName {
    return "nipkg"
}
function Initialize-Provider {
    Write-Debug ("Initialize-Provider")
}

function Find-Package {
    param(
        [string] $name,
        [string] $requiredVersion,
        [string] $minimumVersion,
        [string] $maximumVersion
    )
    $packages = & $script:NIpkgExeName search $name
    for($i=0;$i -le $packages.length-1;$i=$i+2)
    {
      if($request.IsCanceled) { return }
      $option = [System.StringSplitOptions]::RemoveEmptyEntries
      $pkg=$packages[$i].Split("`t",$option)
      Write-Verbose $pkg[0]
      $name=$pkg[0]
      $version=$pkg[1]
      $summary=$pkg[3]
      #for($j=3;$j -lt $pkg.length;$j+=1)
      #{
      #  $summary+=$pkg[$j]+" "
      #}

      $swidObject = @{
             FastPackageReference = $name+"~~"+$version+"~~"+$summary;
             Name = $name;
             Version = $version;
             versionScheme  = "MultiPartNumeric";
             summary = $summary;
             Source = "ni.com";
             }

      $sid = New-SoftwareIdentity @swidObject
      Write-Output -InputObject $sid
    }
}

function Install-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $fastPackageReference
    )

    #Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))
    #Write-Debug -Message ($LocalizedData.FastPackageReference -f $fastPackageReference)
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $name=$fastPackageReference.split("~~", $option)[0]
    $version=$fastPackageReference.split("~~",$option)[1]
    #Write-Verbose $fastPackageReference
    #Write-Verbose $test.length
    #Write-Verbose  $version+"?????????????"
    $packages = & $script:NIpkgExeName install $name  --accept-eulas -y
    Write-Verbose $packages[0]
    #Write-Host $packages[0] -NoNewline
    $swidObject = @{
        FastPackageReference = $name+" "+$version;
        Name = $name;
        Version = $version;
        versionScheme  = "MultiPartNumeric";
        summary = $fastPackageReference.split("~~",$option)[2]
        Source = "ni.com"
        }
    $sid = New-SoftwareIdentity @swidObject
    Write-Output -InputObject $sid
}


function Get-InstalledPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [string]
        $MinimumVersion,

        [Parameter()]
        [string]
        $MaximumVersion
    )

    if($name)
    {
      $packages = & $script:NIpkgExeName list-installed $name
    }
    else
    {
      $packages = & $script:NIpkgExeName list-installed
    }

    for($i=0;$i -le $packages.length-1;$i=$i+2)
    {
      if($request.IsCanceled) { return }
      $pkginfo=$packages[$i].Split("`t")
      $swidObject = @{
             FastPackageReference = $pkginfo[0]+"~~"+$pkginfo[1]+"~~"+$pkginfo[3];
             Name = $pkginfo[0];
             Version = $pkginfo[1];
             versionScheme  = "MultiPartNumeric";
             summary = $pkginfo[3];
             Source = "ni.com";
             }

      $sid = New-SoftwareIdentity @swidObject
      Write-Output -InputObject $sid
    }
}

function UnInstall-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $fastPackageReference
    )
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $name=$fastPackageReference.split("~~", $option)[0]
    $version=$fastPackageReference.split("~~",$option)[1]
    $summary=$fastPackageReference.split("~~",$option)[2]
    $packages = & $script:NIpkgExeName remove $name   -y
    Write-Verbose "uninstall" $name
    #Write-Host $packages[0] -NoNewline
    $swidObject = @{
        FastPackageReference = $name+"~~"+$version+"~~"+$summary;
        Name = $name;
        Version = $version;
        versionScheme  = "MultiPartNumeric";
        summary = $summary
        Source = "ni.com"
        }
    $sid = New-SoftwareIdentity @swidObject
    Write-Output -InputObject $sid

}


function Download-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location
    )


    $force = $false
    $options = $request.Options

    if($options.ContainsKey('Force'))
    {
        $force = $options['Force']
    }

    if(-not $Location -or -not (Test-Path $location)){

       ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage "Path '$Location' is not found" `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Location
    }
    Write-Verbose $Location
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $name=$fastPackageReference.split("~~", $option)[0]
    $version=$fastPackageReference.split("~~",$option)[1]
    $summary=$fastPackageReference.split("~~",$option)[2]

    $packages = & $script:NIpkgExeName download $name --destination-dir=$Location
    $packages =  $packages |Out-String
    Write-Verbose --destination-dir=$Location
    $swidObject = @{
                    FastPackageReference = $fastPackageReference;
                    Name = $name;
                    Version = $version;
                    versionScheme  = "MultiPartNumeric";
                    summary = $summary;
                    Source = "ni.com"
                   }
    $swidTag = New-SoftwareIdentity @swidObject
    Write-Output -InputObject $swidTag
}






function Resolve-PackageSource
{

            #Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSource'))


            $nipkg=& $script:NIpkgExeName feed-list
            #$check=$nipkg |Out-String
            # Write-Verbose $check
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            for($i=0;$i -le $nipkg.length-1;$i=$i+2)
            {
                Write-Verbose ??????????????
                $pkg=$nipkg[$i]
                if($request.IsCanceled) { return }
                $src =  New-PackageSource -Name $pkg.split("`t",$option)[0] `
                                          -Location $pkg.split("`t",$option)[1] `
                                          -Trusted $false `
                                          -Registered $true
                # return the package source object.
                Write-Output -InputObject $src
            }

}




function Add-PackageSource
{
    [CmdletBinding()]
    param
    (
        [string]
        $Name,

        [string]
        $Location,

        [bool]
        $Trusted
    )

    #Write-Verbose "TTTTTTTTTTTTTTTTTTTT"
    # Add new package source

    $nipkg=& $script:NIpkgExeName feed-add --name=$Name $Location

    # yield the package source to OneGet
    Write-Verbose --name=$Name

    $src =  New-PackageSource -Name $Name  `
                              -Location $Location `
                              -Trusted $false `
                              -Registered $true
    # return the package source object.
    Write-Output -InputObject $src

}


function Remove-PackageSource
{
    param
    (
        [string]
        $Name
    )
    Write-Verbose "TTTTTTTTTTTTTTTTTTTT"
    Write-Debug ('Remove-PackageSource')
    $nipkg=& $script:NIpkgExeName feed-remove $Name

}


function ThrowError
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,

        [System.Object]
        $ExceptionObject,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )

    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}
