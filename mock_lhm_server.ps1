param(
    [int]$Port = 8085,
    # SSD (Disk 1)
    [double]$SsdTemp = 28.0,
    [double]$SsdReadAct = 0.0,
    [double]$SsdWriteAct = 45.0,
    [string]$SsdReadStr = "0.0 KB/s",
    [string]$SsdWriteStr = "85.2 MB/s",

    # NVMe (Disk 2)
    [double]$NvmeTemp = 32.0,
    [double]$NvmeReadAct = 0.0,
    [double]$NvmeWriteAct = 60.0,
    [string]$NvmeReadStr = "0.0 KB/s",
    [string]$NvmeWriteStr = "450.0 MB/s",

    # HDD (Disk 3)
    [double]$HddTemp = 25.0,
    [double]$HddReadAct = 0.0,
    [double]$HddWriteAct = 75.0,
    [string]$HddReadStr = "0.0 KB/s",
    [string]$HddWriteStr = "120.0 MB/s"
)

function Get-TelemetryJson {
    # Ensure "Value" strictly precedes "SensorId" in each node object to satisfy Rainmeter WebParser regex
    $json = @"
{
  "id": 0,
  "Text": "Sensor",
  "Children": [
    {
      "id": 1,
      "Text": "Storage",
      "Children": [
        { "id": 10, "Text": "SSD", "Value": "$([string]::Format('{0:0.0}', $SsdTemp)) °C", "SensorId": "/ssd/0/temperature/0" },
        { "id": 11, "Text": "SSD Read Rate", "Value": "$SsdReadStr", "SensorId": "/ssd/0/throughput/54" },
        { "id": 12, "Text": "SSD Write Rate", "Value": "$SsdWriteStr", "SensorId": "/ssd/0/throughput/55" },
        { "id": 13, "Text": "SSD Read Activity", "Value": "$([string]::Format('{0:0.0}', $SsdReadAct)) %", "SensorId": "/ssd/0/load/51" },
        { "id": 14, "Text": "SSD Write Activity", "Value": "$([string]::Format('{0:0.0}', $SsdWriteAct)) %", "SensorId": "/ssd/0/load/52" },

        { "id": 20, "Text": "NVMe", "Value": "$([string]::Format('{0:0.0}', $NvmeTemp)) °C", "SensorId": "/nvme/2/temperature/0" },
        { "id": 21, "Text": "NVMe Read Rate", "Value": "$NvmeReadStr", "SensorId": "/nvme/2/throughput/54" },
        { "id": 22, "Text": "NVMe Write Rate", "Value": "$NvmeWriteStr", "SensorId": "/nvme/2/throughput/55" },
        { "id": 23, "Text": "NVMe Read Activity", "Value": "$([string]::Format('{0:0.0}', $NvmeReadAct)) %", "SensorId": "/nvme/2/load/51" },
        { "id": 24, "Text": "NVMe Write Activity", "Value": "$([string]::Format('{0:0.0}', $NvmeWriteAct)) %", "SensorId": "/nvme/2/load/52" },

        { "id": 30, "Text": "HDD", "Value": "$([string]::Format('{0:0.0}', $HddTemp)) °C", "SensorId": "/hdd/1/temperature/0" },
        { "id": 31, "Text": "HDD Read Rate", "Value": "$HddReadStr", "SensorId": "/hdd/1/throughput/54" },
        { "id": 32, "Text": "HDD Write Rate", "Value": "$HddWriteStr", "SensorId": "/hdd/1/throughput/55" },
        { "id": 33, "Text": "HDD Read Activity", "Value": "$([string]::Format('{0:0.0}', $HddReadAct)) %", "SensorId": "/hdd/1/load/51" },
        { "id": 34, "Text": "HDD Write Activity", "Value": "$([string]::Format('{0:0.0}', $HddWriteAct)) %", "SensorId": "/hdd/1/load/52" }
      ]
    }
  ]
}
"@
    return $json
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "============================================================"
Write-Host " YoRHa Telemetry Mock Server listening on http://localhost:$Port"
Write-Host " Configured Test Values:"
Write-Host "   SSD  : Read=$SsdReadAct% | Write=$SsdWriteAct% | WriteRate=$SsdWriteStr"
Write-Host "   NVMe : Read=$NvmeReadAct% | Write=$NvmeWriteAct% | WriteRate=$NvmeWriteStr"
Write-Host "   HDD  : Read=$HddReadAct% | Write=$HddWriteAct% | WriteRate=$HddWriteStr"
Write-Host " Press Ctrl+C in terminal to stop server."
Write-Host "============================================================"

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::UTF8)

        # Read HTTP request header line
        $requestLine = $reader.ReadLine()
        while (![string]::IsNullOrEmpty($reader.ReadLine())) { }

        $body = Get-TelemetryJson
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)

        $response = "HTTP/1.1 200 OK`r`nContent-Type: application/json; charset=utf-8`r`nAccess-Control-Allow-Origin: *`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n$body"
        $writer.Write($response)
        $writer.Flush()

        $client.Close()
    }
}
finally {
    $listener.Stop()
    Write-Host "Server stopped."
}
