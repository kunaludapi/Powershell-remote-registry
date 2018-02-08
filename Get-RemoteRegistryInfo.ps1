function Get-RemoteRegistryInfo {
[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='GetValue')]
    Param ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = '.',

        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',

        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('ParentKeypath')]
        [String]$RegistryKeyPath,

        [parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ChildKey', 'ValueData')]
        [String]$Type
    
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
            if (Test-Connection $Computer -Count 2 -Quiet) {
                try {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                    $key = $reg.OpenSubKey($RegistryKeyPath, $true)
                }
                catch {
                    Write-Host "Check permissions on computer name $Computer, cannot connect registry" -BackgroundColor DarkRed
                    Continue
                }
                if ($key.GetSubKeyNames() -eq $null -or $key.GetValueNames() -eq $null) {
                    Write-Host "Incorrect registry path on $computer" -BackgroundColor DarkRed
                    continue
                }
                switch ($Type) {
                    'ChildKey' {
                        foreach ($ck in $key.GetSubKeyNames()) {
                            $obj =  New-Object psobject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ChildKey -MemberType NoteProperty -Value $ck
                            $obj
                        }
                        break
                    }
                    'ValueData' {
                        foreach ($vn in $key.GetValueNames()) {
                            $obj =  New-Object psobject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ValueName -MemberType NoteProperty -Value $vn
                            $obj | Add-Member -Name ValueData -MemberType NoteProperty -Value $key.GetValue($vn)
                            $obj | Add-Member -Name ValueKind -MemberType NoteProperty -Value $key.GetValueKind($vn)
                            $obj
                        }
                        break
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

#Get-RemoteRegistryInfo -ComputerName server01, member01 -RegistryHive Users -RegistryKeyPath S-1-5-18 -Type ChildKey
#Get-RemoteRegistryInfo -ComputerName server01, member01 -RegistryHive Users -RegistryKeyPath S-1-5-18\Environment -Type ValueData