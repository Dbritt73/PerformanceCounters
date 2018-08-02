Function Get-PerfBaseLine {
  <#
    .SYNOPSIS
    Describe purpose of "Get-PerfBaseLine" in 1-2 sentences.

    .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER ComputerName
    Describe parameter -ComputerName.

    .EXAMPLE
    Get-PerfBaseLine -ComputerName Value
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online Get-PerfBaseLine

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>


    [CmdletBinding()]
    Param (

        [Parameter( position=0,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$True)]
        [String[]]$ComputerName

    )

    Begin {

        $CounterParams = @{

            'Counter' = '\PhysicalDisk(*)\% Idle Time',
                        '\PhysicalDisk(*)\Avg. Disk sec/Read',
                        '\PhysicalDisk(*)\Avg. Disk sec/Write',
                        '\PhysicalDisk(*)\Current Disk Queue Length',
                        '\Memory\Available Bytes',
                        '\Memory\Pages/Sec',
                        '\Network Interface(*)\Bytes Total/Sec',
                        '\Network Interface(*)\OutPut Queue Length',
                        '\Hyper-V Hypervisor Logical Processor(*)\% Total Run Time',
                        'Paging File(*)\% Usage'
            'ErrorAction' = 'SilentlyContinue'

        }

    }

    Process {

        if ($PSBoundParameters.ComputerName) {

            Foreach ($Computer in $ComputerName) {

                Try {

                    $CounterParams.ComputerName = $Computer

                    $Counters = (Get-Counter @CounterParams).CounterSamples

                    foreach ($counter in $Counters) {

                        $ObjProps = [Ordered]@{

                            'ComputerName' = $Computer;
                            'CounterSetName' = $counter.Path -replace "^\\\\$computer\\|\(.*$";
                            'Counter' = $Counter.path -replace '^.*\\';
                            'Instance' = $Counter.InstanceName;
                            'Value' = $Counter.CookedValue;
                            'TimeStamp' = $Counter.TimeStamp

                        }

                        $Object = New-Object -TypeName PSObject -Property $ObjProps
                        $object.PSObject.typenames.insert(0, 'Performance.Counters')
                        Write-Output -InputObject $Object

                    }

                } Catch {

                    # get error record
                    [Management.Automation.ErrorRecord]$e = $_

                    # retrieve information about runtime error
                    $info = [PSCustomObject]@{

                      Date         = (Get-Date);
                      ComputerName = $Computer;
                      Exception    = $e.Exception.Message;
                      Reason       = $e.CategoryInfo.Reason;
                      Target       = $e.CategoryInfo.TargetName;
                      Script       = $e.InvocationInfo.ScriptName;
                      Line         = $e.InvocationInfo.ScriptLineNumber;
                      Column       = $e.InvocationInfo.OffsetInLine

                    }

                    # output information. Post-process collected info, and log info (optional)
                    $info

                }

            }

        } Else {

            $Counters = (Get-Counter @CounterParams).CounterSamples

                foreach ($counter in $Counters) {

                    $ObjProps = [Ordered]@{

                        'ComputerName' = $ENV:COMPUTERNAME;
                        'CounterSetName' = $counter.Path -replace "^\\\\$ENV:COMPUTERNAME\\|\(.*$";
                        'Counter' = $Counter.path -replace '^.*\\';
                        'Instance' = $Counter.InstanceName;
                        'Value' = $Counter.CookedValue;
                        'TimeStamp' = $Counter.TimeStamp

                    }

                    $Object = New-Object -TypeName PSObject -Property $ObjProps
                    $object.PSObject.typenames.insert(0, 'Performance.Counters')
                    Write-Output -InputObject $Object

                }
        }

    }

    End {}

}