# Ensure TLS 1.2 is enabled for secure module installations
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install SQLServer PowerShell module if not installed
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name SqlServer -Force -AllowClobber
}
Import-Module SqlServer -Force

# Configure SQL Server Authentication
$server = New-Object Microsoft.SqlServer.Management.Smo.Server "(local)"
$server.Settings.LoginMode = [Microsoft.SqlServer.Management.Smo.ServerLoginMode]::Mixed
$server.Alter()
Restart-Service -Name "MSSQLSERVER" -Force

# Create SQL User if it doesn't exist
Invoke-Sqlcmd -Query "
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'adminuser')
BEGIN
    CREATE LOGIN adminuser WITH PASSWORD = 'YourSecurePassword123!';
    ALTER SERVER ROLE sysadmin ADD MEMBER adminuser;
END
" -ServerInstance "(local)" -EncryptConnection -TrustServerCertificate

# Configure Windows Firewall for SQL Server
New-NetFirewallRule -DisplayName "Allow SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
