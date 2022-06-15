$REGISTRY_KEY = "SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$INTERNAL_LARGE_PAGE = "KMD_EnableInternalLargePage"
$AMD_DEVICE_ID = "pci\\ven_1002.*"
$GRAPHICS = "Graphics"
$COMPUTE = "Compute"
$WORKLOAD_TYPE_GRAPHICS = 0
$WORKLOAD_TYPE_COMPUTE = 2

$Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,
    [Microsoft.Win32.RegistryView]::Default)

if ($Registry) {
    $Key = $Registry.OpenSubKey($REGISTRY_KEY, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree)
    
    foreach ($SubKey in $Key.GetSubKeyNames()) {
        if ($SubKey -match "\d{4}") {
            # HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000
            $GPUSettingsKey = $Key.OpenSubKey($SubKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree)
            $GPUName = $Key.GetValue("DriverDesc")
            
            if ($GPUSettingsKey) {
                $DeviceID = $GPUSettingsKey.GetValue("MatchingDeviceId") # pci\ven_1002.*
                if ($DeviceID -match $AMD_DEVICE_ID ) {
                    $InternalLargePageValue = $GPUSettingsKey.GetValue($INTERNAL_LARGE_PAGE)

                    if ($InternalLargePageValue -eq $WORKLOAD_TYPE_GRAPHICS) {
                        $Mode = $GRAPHICS
                        $NextMode = $COMPUTE
                    }
                    else {
                        $Mode = $COMPUTE
                        $NextMode = $GRAPHICS
                    }

                    "GPU [$GPUName] with ID [$($DeviceID)] is currently set to [$Mode], setting to [$NextMode]"
                    $GPUSettingsKey = $Key.OpenSubKey($SubKey, $true) # Open in write mode -> requires administrator privileges
                    
                    if ($InternalLargePageValue -eq $WORKLOAD_TYPE_GRAPHICS) {
                        $MODE_TO_SET = $WORKLOAD_TYPE_COMPUTE
                    }
                    else {
                        $MODE_TO_SET = $WORKLOAD_TYPE_GRAPHICS
                    }
                    
                    # $GPUSettingsKey.SetValue($INTERNAL_LARGE_PAGE, $MODE_TO_SET, [Microsoft.Win32.RegistryValueKind]::DWord)
                }
                else {
                    "Error: $DeviceID is not an AMD GPU"
                }
            }
        }
    }	
	
    $Registry.Close()
    $Registry.Dispose()
    Read-Host "Press enter to close..."
}