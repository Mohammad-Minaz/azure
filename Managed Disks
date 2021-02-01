#Get-AzDisk
$managedDisks = Get-AzDisk
foreach ($md in $managedDisks) {
    if($md.ManagedBy -eq $null){
		if($md.tags."Do-Not-Delete" -eq "yes" -Or $md.tags."Do-Not-Delete" -eq "y" -Or $md.tags."do-not-delete" -eq "yes" -Or $md.tags."do-not-delete" -eq "y" -Or $md.tags."DND" -eq "y" -Or $md.tags."DND" -eq "Yes"-Or $md.tags."dnd" -eq "y" -Or $md.tags."dnd" -eq "Yes"){
			Write-Host "Skipping: " $md.Id  "`r`ntags: " $md.Tags -ForegroundColor Green   
		}else{
			Write-Host "Deleting unattached Managed Disk with Id: $($md.Id) "
			$md | Remove-AzDisk -Force
			Write-Host "Deleted unattached Managed Disk with Id: $($md.Id) "
		}
	}
}
