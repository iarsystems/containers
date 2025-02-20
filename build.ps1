# Powershell

<# Copyright (c) 2022-2025 IAR Systems AB
 #
 # build.ps1 - Build a Docker image containing the IAR Build Tools
 # 
 # See LICENSE for detailed license information
 #>

[CmdletBinding()]
param(
    # [parameter(Mandatory=$true)]
    # /path/to/bx<arch>-<version>.exe installer package.
    [String]${package}
)

# Define supported architectures and their validation regex
$SupportedArchitectures = @{
    'arm'    = '^bxarm(?:fs)?-[\d\.]+\.exe$'
    'rh850'  = '^bxrh850(?:fs)?-[\d\.]+\.exe$'
    'riscv'  = '^bxriscv(?:fs)?-[\d\.]+\.exe$'
    'rl78'   = '^bxrl78-[\d\.]+\.exe$'
    'rx'     = '^bxrx-[\d\.]+\.exe$'
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Level - $Message"
}

function Show-Help {
    Write-Log "Usage: $($MyInvocation.MyCommand.Definition) [options] /path/to/bx<package>.exe"
    Write-Log "Options:"
    Write-Log "  -skipCleanup     Skip cleanup of temporary files"
    Write-Log " "
}

function Test-InstallerPackage {
    param(
        [string]$PackagePath
    )
    
    # Verify file exists
    if (-not (Test-Path -Path $PackagePath -PathType Leaf)) {
        throw "ERROR: File -${PackagePath}- not found."
    }
    
    # Verify file extension
    if (-not ($PackagePath -match '\.exe$')) {
        throw "ERROR: Invalid file extension. Expected .exe file."
    }
    
    # Get file hash for integrity check
    $fileHash = Get-FileHash -Path $PackagePath -Algorithm SHA256
    Write-Output "Package SHA256: $($fileHash.Hash)"
    
    # Verify file signature (if available)
    try {
        $signature = Get-AuthenticodeSignature -FilePath $PackagePath
        if ($signature.Status -ne 'Valid') {
            Write-Warning "Package signature validation failed: $($signature.Status)"
        }
    }
    catch {
        Write-Warning "Could not verify package signature: $_"
    }
}

function Get-PackageInfo {
    param(
        [string]$PackagePath
    )
    
    $PkgFullPath = Get-ChildItem -Path $PackagePath
    $PkgPath = Split-Path $PkgFullPath -Parent
    $PkgFile = Split-Path $PkgFullPath -leaf
    $PkgBase = $PkgFile.TrimEnd(".exe")
    $PkgName = $PkgBase.Split("-")[0]
    $PkgVersion = $PkgBase.Split("-")[1].Split(".")[0..2] -join "."
    $PkgVersionExtended = $PkgBase.Split("-")[-1] 
    
    # Validate package name against supported architectures
    $matchFound = $false
    foreach ($arch in $SupportedArchitectures.Keys) {
        if ($PkgFile -match $SupportedArchitectures[$arch]) {
            $BxArch = $arch
            $matchFound = $true
            break
        }
    }
    
    if (-not $matchFound) {
        throw "ERROR: Invalid package name format. Must match one of the supported architectures."
    }
    
    return @{
        FullPath = $PkgFullPath
        Path = $PkgPath
        File = $PkgFile
        Name = $PkgName
        Version = $PkgVersion
        Arch = $BxArch
    }
}

try {
    Write-Log "Starting build process..."
    
    # Validate and get package info
    Test-InstallerPackage -PackagePath $package
    $pkgInfo = Get-PackageInfo -PackagePath $package
    
    # Copy installer to build context
    $ScriptPath = Split-Path $PSCommandPath -Parent
    $DestinationPath = Join-Path $ScriptPath $pkgInfo.File
    
    if (Test-Path $DestinationPath) {
        Write-Log "File already exists at $DestinationPath. Verifying integrity..."
        $srcHash = Get-FileHash -Path $package -Algorithm SHA256
        $dstHash = Get-FileHash -Path $DestinationPath -Algorithm SHA256
        
        if ($srcHash.Hash -ne $dstHash.Hash) {
            Write-Log "File hash mismatch. Copying new version..."
            Copy-Item $package $DestinationPath -Force
        }
    }
    else {
        Write-Log "Copying installer to build context..."
        Copy-Item $package $DestinationPath
    }
    
    # Build Docker image
    $imageName = "iarsystems/$($pkgInfo.Name):$($pkgInfo.Version)"
    Write-Log "Building Docker image: $imageName"
    
    $buildArgs = @(
        "build",
        "-f", "Dockerfile_windows",
        "--tag", $imageName,
        "--build-arg", "BX_PACKAGE_EXE=$($pkgInfo.File)",
        "--build-arg", "BX_VERSION=$($pkgInfo.Version)"
    )
    
    $buildArgs += $ScriptPath
    
    $buildProcess = Start-Process -FilePath "docker" -ArgumentList $buildArgs -NoNewWindow -PassThru -Wait
    if ($buildProcess.ExitCode -ne 0) {
        throw "Docker build failed with exit code: $($buildProcess.ExitCode)"
    }
    
    Write-Log "Docker image build completed successfully"
    
    # Cleanup
    if (-not $skipCleanup) {
        Write-Log "Cleaning up temporary files..."
        Remove-Item $DestinationPath -ErrorAction SilentlyContinue
    }
    
    Write-Log "Build process completed successfully"
}
catch {
    Write-Error "Build failed: $_"
    exit 1
}