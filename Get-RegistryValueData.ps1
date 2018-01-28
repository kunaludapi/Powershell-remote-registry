function Get-RegistryValueData {
    [CmdletBinding(SupportsShouldProcess=$True,
        ConfirmImpact='Medium',
        HelpURI='http://vcloud-lab.com')]
    Param
    ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = '.',
        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)] 
        [alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',
        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('KeyPath')]
        [String]$RegistryKeyPath = 'SYSTEM\CurrentControlSet\Services\USBSTOR',
        [parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [alias('Value')]
        [String]$ValueName = 'Start'
    )
    Begin {
        $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
        try {
            $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        }
        catch {
            Write-Host "Incorrect Registry Hive mentioned, $RegistryHive does not exist" 
        }
    }
    Process {
        Foreach ($Computer in $ComputerName) {
            if (Test-Connection $computer -Count 2 -Quiet) {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                $key = $reg.OpenSubKey($RegistryKeyPath)
                $Data = $key.GetValue($ValueName)
                $Obj = New-Object psobject
                $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value "$RegistryKeyPath\$ValueName"
                $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $Data
                $Obj
            }
            else {
                Write-Host "$Computer not reachable" -BackgroundColor DarkRed
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


Get-RegistryValueData -ComputerName Server01, Member01, testcomp -RegistryHive LocalMachine -RegistryKeyPath SYSTEM\CurrentControlSet\Services\USBSTOR -ValueName 'Start'
