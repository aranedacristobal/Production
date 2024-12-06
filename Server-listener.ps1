$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, 65432)
$listener.Start()
Write-Host "Server started..."

while ($true) {
    $client = $listener.AcceptTcpClient()
    Write-Host "Client connected"
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)

    $data = $reader.ReadLine()
    Write-Host "Received: $data"
    $writer.WriteLine("Hello, Client!")
    $writer.Flush()
    $client.Close()
}