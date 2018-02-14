function Get-InstalledSoftwareInfo {
<#  
  .Synopsis  
    Get installed software information from remote computer.
  .Description  
    This cmdlet Get-InstalledSoftwareInfo will fetch and retrive information from remote and local computer. This requires remote registry service to be running. 
  .Example  
    Get-InstalledSoftwareInfo -ComputerName Server01
     
   This retrives list from computername server01
  .Example
    Get-InstalledSoftwareInfo -ComputerName Server01 | Export-CSV -Path c:\temp\info.csv
    Get-InstalledSoftwareInfo -ComputerName Server01 | ft

    Using pipeline information can be exported to CSV or shows tablewise
  .OutPuts  
    ComputerName DisplayName                                                    DisplayVersion Publisher             InstallDate EstimatedSize   
    ------------ -----------                                                    -------------- ---------             ----------- --------
    Server01     Microsoft Visual C++ 2012 x64 Additional Runtime - 11.0.61030  11.0.61030     Microsoft Corporation 20171225    5.82MB  
    Server01     Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.6161 9.0.30729.6161 Microsoft Corporation 20170820    1.04MB 
  .Notes  
    NAME: Get-InstalledSoftwareInfo
    AUTHOR: Kunal Udapi
    CREATIONDATE: 02 January 2018
    LASTEDIT: 7 January 2017  
    KEYWORDS: Get installed software application information
  .Link  
   #Check Online version: http://kunaludapi.blogspot.com
   #Check Online version: http://vcloud-lab.com
   #Requires -Version 3.0  
  #>
[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com')]
    Param ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = 'server01' #'.'
    )
    Begin {
    }
    Process {
        Foreach ($Computer in $ComputerName) {
            if (Test-Connection $Computer -Count 2 -Quiet) {
                $RegistryHive = 'LocalMachine'
                $RegistryKeyPath = $('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
                $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
                $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
                foreach ($regpath in $RegistryKeyPath) {
                    try {
                        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                        $key = $reg.OpenSubKey($regpath, $true)
                    }
                    catch {
                        Write-Host "Check permissions on computer name $Computer, cannot connect registry" -BackgroundColor DarkRed
                        Continue
                    }
                    foreach ($subkey in $key.GetSubKeyNames()) {
                        $Childsubkey = $key.OpenSubKey($subkey)
                        $SoftwareInfo = $Childsubkey.GetValueNames()
                        $Displayname = $Childsubkey.GetValue('DisplayName')
                        [Int]$rawsize = $Childsubkey.GetValue('EstimatedSize')
                        $ConvertedSize = $rawsize / 1024
                        $SoftwareSize = "{0:N2}MB" -f $ConvertedSize
                        if ($SoftwareInfo -contains 'DisplayName') {
                            $SoftInfo = [PSCustomObject]@{
                                ComputerName = $Computer
                                DisplayName = $Childsubkey.GetValue('DisplayName')
                                DisplayVersion = $Childsubkey.GetValue('DisplayVersion')
                                Publisher = $Childsubkey.GetValue('Publisher')
                                InstallDate = $Childsubkey.GetValue('InstallDate')
                                EstimatedSize = $SoftwareSize
                                InstallLocation = $Childsubkey.GetValue('InstallLocation')
                                InstallSource = $Childsubkey.GetValue('InstallSource')
                                UninstallString = $Childsubkey.GetValue('UninstallString')
                                RegistryLocation = $Childsubkey.Name
                            }
                            $SoftInfo
                        }
                        $Childsubkey.close()
                    }
                $key.close()
                }
            }
            else {
                Write-Host "Computer Name $Computer not reachable" -BackgroundColor DarkRed
            }
        }
    }
    End {
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}
Get-InstalledSoftwareInfo -ComputerName Server01, Member01 | ft
