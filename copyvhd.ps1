 param(

        [Parameter(Mandatory=$true)]
        [string] 
        $dest_storageAccountName,
    
        [Parameter(Mandatory=$true)]
        [string] 
        $destContainerName,

        [Parameter(Mandatory=$true)]
        [string] 
        $destStorageAccountKey,

        [Parameter(Mandatory=$true)]
        [string] 
        $desteblob,
        
        [Parameter(Mandatory=$true)]
        [string] 
        $SourceStorageAccountName,

        [Parameter(Mandatory=$true)]
        [string] 
        $Sourcecontainer,

        [Parameter(Mandatory=$true)]
        [string] 
        $sourceVHDname,

        [Parameter(Mandatory=$true)]
        [string] 
        $sourceVhdURL,

        [Parameter(Mandatory=$true)]
        [string] 
        $sourceSasToken,

        [Parameter(Mandatory=$true)]
        [string] 
        $SourceStorageAccountKey
)

        # Credentials
        $myCredential = Get-AutomationPSCredential -Name 'automationCredentials'
		$userName = $myCredential.UserName
		$securePassword = $myCredential.Password
		##Destination Storage Account : 
        #$dest_storageAccountName = "stgnsstst0012"
		#$destContainerName = "zscalernssrprod"
		#$destStorageAccountKey = 'YdRtwa2pu5hRhD77D2xNnlfly5lJ1UeL3NUz/ILhaARS9eghjdQ9uojwyO8XZSiBIdrQEBA6yY+Q+AStnyRdpA=='        
		$destContext = New-AzStorageContext -StorageAccountName $dest_storageAccountName -StorageAccountKey $destStorageAccountKey
        #$desteblob = "vhd.disk"
        ##Source Storage Account (znss) : 
        #$SourceStorageAccountName = "stgnsstst0012"
        #$Sourcecontainer = "vhd"
		#$sourceVHDname = "disk.vhd"
		#$sourceVhdURL = "https://stgnsstst0012.blob.core.windows.net/vhd/disk.vhd?"
		#$sourceSasToken = "sp=rwi&st=2022-07-24T15:43:23Z&se=2022-07-24T23:43:23Z&sv=2021-06-08&sr=b&sig=aToNYaxRqUkwY1RVRv6WZd3ksBE1aLzVbkProQQur70%3D"
		$sasVHDurl=$sourceVhdURL+$sourceSasToken
        #$SourceStorageAccountKey = 'YdRtwa2pu5hRhD77D2xNnlfly5lJ1UeL3NUz/ILhaARS9eghjdQ9uojwyO8XZSiBIdrQEBA6yY+Q+AStnyRdpA=='
        $SourceContext = New-AzStorageContext -StorageAccountName $SourceStorageAccountName -StorageAccountKey $SourceStorageAccountKey

		
        echo 'start the copy'
		Start-AzStorageBlobCopy -AbsoluteUri $sasVHDurl -DestContainer $destContainerName -DestBlob $desteblob -DestContext $destContext -Force
		echo 'start chekcing '
		$vhdCopyStatus=Get-AzStorageBlobCopyState -Context $destContext -Blob $desteblob -Container $destContainerName -WaitForComplete
	    While($vhdCopyStatus.Status -ne "Success") {
    		if($vhdCopyStatus.Status -ne "Pending") {
        		echo "Error copying the VHD"
        		exit
        		}
		$vhdCopyStatus=Get-AzStorageBlobCopyState -Context $destContext -Blob $desteblob -Container $destContainerName 
    		echo "VHD copying is in progress" $vhdCopyStatus.BytesCopied "bytes copied of" $vhdCopyStatus.TotalBytes
    		sleep 5
		}
		echo "The VHD has been successfully copied"
