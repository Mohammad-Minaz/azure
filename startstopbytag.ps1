workflow ShutDownStartByTag 
{ 
        Param( 
        [Parameter(Mandatory=$true)] 
        [String] 
        $TagName, 
        [Parameter(Mandatory=$true)] 
        [String] 
        $TagValue, 
        [Parameter(Mandatory=$true)] 
        [Boolean] 
        $Shutdown 
        ) 
      
    $connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
 
    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
} 
          
      
    $vms = Find-AzResource -TagName $TagName -TagValue $TagValue | where {$_.ResourceType -like "Microsoft.Compute/virtualMachines"} 
      
    Foreach -Parallel ($vm in $vms){ 
         
        if($Shutdown){ 
            Write-Output "Stopping $($vm.Name)";         
            Stop-AzVm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force; 
        } 
        else{ 
            Write-Output "Starting $($vm.Name)";         
            Start-AzVm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName; 
        } 
    } 
}
