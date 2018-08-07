[CmdletBinding()]
param (
  [Microsoft.Management.Infrastructure.CimSession]$CimSession
)

Begin {

    $Params = @{}

    if (-not($PSBoundParameters.CimSession)) {

        $Counters = Get-PerfBaseLine

    } else {

        $Params.CimSession = $CimSession
        $Counters = Get-PerfBaseLine -ComputerName $CimSession.ComputerName

    }

    $Computer = $Counters[0].ComputerName

    Function ConvertTo-HashTable {
    <#
        .SYNOPSIS
        Describe purpose of "ConvertTo-HashTable" in 1-2 sentences.

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER InputObject
        Describe parameter -InputObject.

        .PARAMETER MemberType
        Describe parameter -MemberType.

        .EXAMPLE
        ConvertTo-HashTable -InputObject Value -MemberType Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online ConvertTo-HashTable

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>



        [CmdletBinding()]

        param (

            [Parameter( Position = 0, 
                        Mandatory = $true,
                        ValueFromPipeline = $true,
                        HelpMessage = 'Select-Object property, maintaining typename header')]
            [PSObject[]]$InputObject,

            [ValidateSet('Property', 'NoteProperty')]
            [Parameter( Position = 1,
                        HelpMessage = 'Property or NoteProperty')]
            [String]$MemberType = 'NoteProperty'

        )

        Begin {

            $ErrorActionPreference = 'stop'

        }

        Process {

            Try {

                $hashtable = @{}

                foreach ($Obj in $InputObject) {

                    foreach ( $Prop in (Get-Member -InputObject $Obj -MemberType $MemberType) ) {

                        $hashtable.($Prop.Name) = $Obj.($Prop.Name)

                    }

                    Write-Output -InputObject $hashtable

                }

            } Catch {

                # get error record
                [Management.Automation.ErrorRecord]$e = $_

                # retrieve information about runtime error
                $info = [PSCustomObject]@{

                Exception = $e.Exception.Message
                Reason    = $e.CategoryInfo.Reason
                Target    = $e.CategoryInfo.TargetName
                Script    = $e.InvocationInfo.ScriptName
                Line      = $e.InvocationInfo.ScriptLineNumber
                Column    = $e.InvocationInfo.OffsetInLine

                }

                # output information. Post-process collected info, and log info (optional)
                Write-output -InputObject $info

            }

        }

        End {}

    }
    
}

Process {

    Describe -Name "Physical Disk Performance for $Computer" -Fixture {

        Context -Name "Physical Disk Current Disk Queue Length for $Computer" -Fixture {
    
            $Counter = 'Current Disk Queue Length'
    
            $Cases = $Counters.Where({ $_.Counter -eq $Counter -and $_.Instance -ne '_total'}) |
    
            Select-Object -Property Instance | ConvertTo-HashTable
    
            It -name 'Should Not Be Greater than 2 for : <Instance>' -TestCases $Cases -test {
    
                Param ($Instance)
    
                $Counters.Where({$_.Instance -eq $Instance -and $_.Counter -eq $Counter}).Value | 
                
                Should -Not -BeGreaterThan 2
    
            }
    
        }
    
        Context -Name "Physical Disk % Idle Time for $Computer" -Fixture {
        
            $Counter = '% Idle Time'
        
            $Cases = $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -ne '_total'}) | 
            
                Select-Object -Property 'Instance' | 
                
                    ConvertTo-HashTable
        
            it -name 'Should Not Be Less than 60% for: <Instance>' -TestCases $Cases -test {
    
                Param ($Instance)
        
                $Counters.Where({$_.Instance -eq $Instance -and $_.Counter -eq $Counter})
    
            }
    
        }
    
        Context -Name "Physcial Disk Avg. Disk Sec/Read for $Computer" -Fixture {
        
            $Counter = 'Avg. Disk Sec/Read'
        
            $Cases = $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -ne '_total'}) | 
            
                Select-object -Property 'Instance' | ConvertTo-HashTable
        
            It -name 'Should Not be Greater 20ms for: <Instance>' -TestCases $Cases -test {
        
                Param ($Instance)
        
                ($Counters.Where({$_.Instance -eq $Instance -and $_.Counter -eq $Counter}).Value * 1000 -as [decimal]) | 
                
                    Should -Not -BeGreaterThan 20
        
            }
        
        }
    
        Context -Name "Physical Disk Avg. Disk Sec/Write for $Computer" -Fixture {
        
            $Counter = 'Avg. Disk sec/Write'
        
            $Cases = $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -ne '_total'}) | 
            
                Select-object -Property 'Instance' | ConvertTo-HashTable
        
            It -name 'Should Not Be Greater than 20ms for: <Instance>' -TestCases $Cases {
        
                Param ($instance)
        
                $Counters.Where({$_.Instance -eq $Instance -and $_.Counter -eq $Counter}).Value * 1000 -as [Decimal] | 
                
                    Should -Not -BeGreaterThan 20
        
            }
        
        }
    
    }
    
    Describe -Name "Memory Performance for $computer" -Fixture {
    
        Context -Name "Memory Available Bytes for $Computer" -Fixture {
    
            It -name 'Should Not Be Less than 10% Free' -test {
    
                (($Counters.Where({
                    
                    $_.Counter -eq 'Available Bytes'
                
                }).Value) / 1MB) / ((Get-CimInstance -ClassName 'Win32_PhysicalMemory' -Property 'Capacity' | 
                
                    Measure-Object -Property 'Capacity' -Sum).Sum / 1MB) * 100 -as [int] |
    
                    Should -Not -BeLessThan 10
    
            }
    
        }
    
        Context -Name "Memory Pages/sec for $Computer" -Fixture {
    
            It 'Should not be greater than 1000' {
    
                $Counters.where({$_.Counter -eq 'Pages/sec'}).Value | Should -not -BeGreaterThan 1000
    
            }
    
        }
    
        Context -Name "Paging File % Usage for $Computer" -Fixture {
    
            $Counter = '% Usage'
    
            $Cases = $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -ne '_total'}).Value |

                Select-Object -Property 'Instance' | ConvertTo-HashTable
    
            It -name 'Should not be Greater than 10% for: <Instance>' -TestCases $Cases {
    
                Param($Instance)
    
                $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -eq $instance}).Value |
    
                    Should -Not -BeGreaterThan 10
    
            }
    
        }
    
    }
    
    Describe -Name "Network Performance for $Computer" -Fixture {
    
        Context -Name "Network Interface Bytes Total/Seceond for $Computer" -Fixture {
    
            $Counter = 'Bytes Total/Sec'
    
            $Cases = $counters.Where({ $_.Counter -eq $counter -and $_.Instance -notmatch 'isatap'}) |
    
            Select-object -Property Instance | ConvertTo-HashTable
    
            It -name "Should not be Greater than 65% for <Instance>: " -TestCases $Cases {
    
                Param ($Instance)
    
                ($Counters.Where({
                    
                    $_.Instance -eq $Instance -and $_.Counter -eq $Counter
                
                }).Value) / ((Get-NetAdapter -Physical).Speed) * 100 | Should -Not -BeGreaterThan 65
    
                #((Get-NetAdapter @Params -InterfaceDescription ($Instance -replace '\[', '(' -replace '\]', ')' -replace '_', '#')).Speed) * 100 | Should -Noot -BeGreaterThan 65
    
            }
    
        }
    
        Context -Name "Network Interface Outpuut Queue Length for $Computer" -Fixture {
    
            $Counter = 'Output Queue Length'
    
            $Cases = $Counters.Where({$_.Counter -eq $Counter -and $_.Instance -notmatch 'isatap'}) | 
            
                Select-Object -Property Instance | ConvertTo-HashTable
    
            It -name "Should not be greater than 2 for : <Instance>" -TestCases $Cases {
    
                Param ($Instance)
    
                $Counters.Where({$_.Instance -eq $Instance -and $_.Counter -eq $Counter}).Value | 
                
                    Should -Not -BeGreaterThan 2
    
            }
    
        }
    
    }
    
    Describe -Name "Hyper-V Performance for $Computer" -Fixture {
    
        Context -Name "Hyper-V Logical Processor % Total RunTime for $computer" -Fixture {
    
            $Counter = '% Total Run Time'
    
            $Cases = $Counters.Where({$_.Counter -eq $Counter}) | Select-Object -Property 'Instance' | ConvertTo-HashTable
    
            It 'Should Not Be Greater than 90% for: <Instance>' -TestCases $Cases {
    
                Param($Instance)
    
                $Counters.Where({$_.Instnace -eq $Instance -and $_.Counter -eq $Counter}).Value | 
                
                    Should  -Not -BeGreaterThan 90
    
            }
    
        }
    
    }

}

End {}