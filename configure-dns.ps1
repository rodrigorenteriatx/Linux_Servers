    # PowerShell script to configure DNS server on Windows
    $InterfaceName = "Ethernet 2" #
    $PrimaryDNS = "10.0.1.144"

    # Set the primary DNS server
    netsh interface ip set dns name="$InterfaceName" source=static addr=$PrimaryDNS

