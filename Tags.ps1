$VMs = Get-AzVm
ForEach ($VM in $VMs){
	if($VM | Where {$_.Tags."Name" -eq "$null" -Or $_.Tags."Owner" -eq "$null"  -Or $_.Tags."Team" -eq "$null" -Or $_.Tags."Timeline" -eq "$null" -Or $_.Tags."Project" -eq "$null" -Or $_.Tags."Role" -eq "$null"  -Or $_.Tags."Environment" -eq "$null"}){
		Stop-AzVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force
		Write-Output "[$($vm.Name)] "
        Write-Host "Your server is needed Tags"
	}else{
		Write-Host "Your server is having All Tags"	
        Write-Output "[$($vm.Name)] "
	}
}
