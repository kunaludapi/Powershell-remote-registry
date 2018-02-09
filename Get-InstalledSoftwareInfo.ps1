function Get-InstalledSoftwareInfo {
[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com')]
    Param ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = '.'
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
                        if ($Displayname -ne $null) {
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
                        }
                        $SoftInfo 
                        #break
                    }
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
#Get-InstalledSoftwareInfo -ComputerName Server01, Member01