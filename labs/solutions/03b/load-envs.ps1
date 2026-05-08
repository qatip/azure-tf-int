Get-Content ./sp_credentials.env | ForEach-Object {
    $key, $value = $_ -split "="
    Set-Item -Path "Env:$key" -Value $value
}