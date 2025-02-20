# Powershell

<# Copyright (c) 2022-2025 IAR Systems AB
 #
 # setup-license.ps1 - License configuration for the bx-docker images
 # 
 # See LICENSE for detailed license information
 #>

param(
  # DockerImage
  [String]${global:PkgNameVersion},
  # LMS2 server IP
  [String]${global:lms2ip}
  )

function Show-Help {
  Write-Output "Usage: setup-license.ps1 <iarsystems/bx<image>:<tag>> <iar-license-server-ip>"
  Write-Output "Example:"
  Write-Output ".\setup-license.ps1 iarsystems/bxarm:9.60.3 iar-license-server.corp.com"
  Write-Output " "
}

if (-not $PkgNameVersion -or -not $lms2ip) {
  Write-Output "ERROR: Missing required parameters."
  Show-Help
  exit 1
}

# Uncomment below code block to create a Docker volume for storing persistent license information, if you need
# and use the docker volume with run command.
# # Check for any existing LMS2 Docker Volume
# ${BxLMS2Volume} = docker volume ls | select-string LMS2
# if (-not ${BxLMS2Volume}) {
#   Write-Output "-- setup-license: Creating a Docker volume for storing persistent license information..."
#   docker volume create LMS2
#   if ($LASTEXITCODE -ne 0) {
#     Write-Error "Failed to create Docker volume LMS2."
#     exit 1
#   }
# }


# Verify License Server Connectivity
Write-Output "-- setup-license: Verifying License Server connectivity..."
$pingResult = Test-NetConnection -ComputerName $global:lms2ip -Port 5093
if ($pingResult.TcpTestSucceeded -eq $false) {
  Write-Error "-- setup-license: Failed to connect to the License Server."
  exit 1
} else {
  Write-Output "-- setup-license: Successfully connected to the License Server."
}

# Fetch the image version from the given package input
$imageVersion = $global:PkgNameVersion.Split(":")[1].Split(".")[0..2] -join "."
Write-Output "-- setup-license: Running Docker container for license setup..."
docker run --detach --tty --name win-iar-bx-container $global:PkgNameVersion

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to run Docker container for license setup."
  exit 1
}

Write-Output "-- setup-license: Wait for 30 seconds before executing the license setup..."
sleep 30 # A loop can be added to check the container status before executing the license setup

# License manager path
$licenseManagerPath = "C:\iar\bxarm-$imageVersion\common\bin\LightLicenseManager.exe"

# Execute the license setup command
Write-Output "-- setup-license: Running license setup command..."
docker exec win-iar-bx-container $licenseManagerPath setup -s $global:lms2ip

# Check the exit code
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to execute license setup command."
  docker rm -f win-iar-bx-container 
  exit 1
}

# Stop the container
docker stop win-iar-bx-container
Write-Output "-- setup-license: LMS2 license setup completed."