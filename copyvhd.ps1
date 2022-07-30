 param(
        [Parameter(Mandatory=$true)]
        [string] 
        $NEWSTORAGEACCOUNTNAME,
    
        [Parameter(Mandatory=$true)]
        [string] 
        $NEWSTORAGEACCOUNTCONTAINERNAME,

        [Parameter(Mandatory=$true)]
        [string] 
        $DESTVHDNAME,

        [Parameter(Mandatory=$true)]
        [string] 
        $VHDURL,

        [Parameter(Mandatory=$true)]
        [string] 
        $SASTOKEN,
        [Parameter(Mandatory=$true)]
        [string] 
        $STORAGEACCOUNTKEY	

)

        # Credentials
        $myCredential = Get-AutomationPSCredential -Name 'automationCredential'
        $userName = $myCredential.UserName
	$securePassword = $myCredential.Password        
	$destContext = New-AzStorageContext -StorageAccountName $dest_storageAccountName -StorageAccountKey $StorageAccountKey
	$sasVHDurl=$VHDURL+'?'+$SASTOKEN
	
				
        echo 'start the copy'
	Start-AzStorageBlobCopy  -AbsoluteUri $sasVHDurl -DestContainer $NEWSTORAGEACCOUNTCONTAINERNAME -DestBlob $DESTVHDNAME -DestContext $destContext -Force
	echo 'start chekcing '
	$vhdCopyStatus=Get-AzStorageBlobCopyState -Context $destContext -Blob $DESTVHDNAME -Container $NEWSTORAGEACCOUNTCONTAINERNAME
	While($vhdCopyStatus.Status -ne "Success") {
    		if($vhdCopyStatus.Status -ne "Pending") {
        		echo "Error copying the VHD"
        		exit
        		}
	$vhdCopyStatus=Get-AzStorageBlobCopyState -Context $destContext -Blob $DESTVHDNAME -Container $NEWSTORAGEACCOUNTCONTAINERNAME
    		echo "VHD copying is in progress" $vhdCopyStatus.BytesCopied "bytes copied of" $vhdCopyStatus.TotalBytes
    		sleep 5
			}
	echo "The VHD has been successfully copied"
