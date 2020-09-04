<#
.Synopsis
    Author: Rajeev Buggaveeti
    Version: 1.1
    Remarks: The following enhancements are in pipeline:
    Porting to workflow
    OMS setup with alerting once a day to show the status of the VMS.

    Name: ScheduledVMStartStoByTags
.DESCRIPTION
    Start and Stop Azure VMs by tag.
    This script finds all the Azure Virtual Machines across your subscriptions based on a tag.
    Those machines are then Started or Stopped(Deallocated) based on a defined schedule.
    By default this script includes Saturday, Sunday and specific hours(needs input) per day in schedule.

.INPUTS
    Input $tagname & $tagvalue when prompted. While its not case sensitive, please enter the correct tags.
    Input $starttime & $stoptime when prompted. These have to be in the following formats:
    06:00 AM
    06:00:00 AM
    18:00
    18:00:00
    Do NOT enter the date as the script will pick it up based on execution
.OUTPUTS
    This will output time conversion, VM Status
.NOTES
    This script is built with a logic that the VMs needs to be stopped(Deallocated) during weekend and
    After Business hours.
#>
Param(
    [Parameter(Mandatory = $true)]
    [String]
    $tagname,
    [Parameter(Mandatory = $true)]
    [String]
    $tagvalue,
    [Parameter(Mandatory = $true)]
    [String]
    $starttime,
    [Parameter(Mandatory = $true)]
    [String]
    $stoptime
)
     
$connectionName = "AzureRunAsConnection";
#$starttime =Get-Date "06:00:00 AM"
#$stoptime =Get-Date "06:00:00 PM"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName        
 
    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
 
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Get all subscriptions
Write-Output 'Retrieving Subscriptions...'
$Subscriptions = Get-AzureRmSubscription
Write-Output 'Subscriptions Retrieved:'
#$Subscriptions

Write-output 'PowerShell Variables inputs are..'
$tagname
$tagvalue
$starttime
$stoptime
#Time and Day Check

$Now = (Get-Date).ToUniversalTime()  
Write-output "Current Time in UTC: "$Now
$destzone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
$NowPST = [System.TimeZoneInfo]::ConvertTimeFromUtc($Now, $destzone)
Write-output "Current Time in PST: "$NowPST
    
$starttime=$nowpst.ToShortDateString()+"`t"+$starttime
$starttime = Get-Date $starttime

$stoptime=$nowpst.ToShortDateString()+"`t"+$stoptime
$stoptime = Get-Date $stoptime

write-output 'Start Time in PST:'$starttime
write-output 'Stop Time in PST:'$stoptime
     
$vms = $null
foreach ($subs in $Subscriptions) {
    Set-AzureRmContext -Subscription $subs.Id | Out-Null
 
    $vms = Get-AzureRmResource -tagname $tagname -tagvalue $tagvalue | where {$_.ResourceType -like "Microsoft.Compute/virtualMachines"}

    If ($vms.count -ne "0") {
        foreach ($vm in $vms) {
            $VMStatus = Get-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            $currentStatus = $VMStatus.Statuses | where Code -like "PowerState*" 
            $currentStatus = $currentStatus.Code -replace "PowerState/", ""

            if ($NowPST.DayOfWeek -eq "Saturday" -or $NowPST.DayOfWeek -eq "Sunday" -or $NowPST -ge $stoptime -or $NowPST -le $starttime) {
                # Get VM with current status
                Write-output 'VM Status:'$vm.Name+"`t"+$currentStatus

                If ($currentStatus -ne "deallocated") {
                    Write-Output "Stopping(Deallocating) $($vm.Name)"
                    $VMStatus | Stop-AzureRmVM -Force
                }
            
            }
            elseif ($currentStatus -notmatch "running") {
                Write-output 'VM Status:'$vm.Name+"`t"+$currentStatus
                Write-Output "Starting $($vm.Name)"       
                $VMStatus | Start-AzureRmVM 
                
            }

        }
        
    }
}
