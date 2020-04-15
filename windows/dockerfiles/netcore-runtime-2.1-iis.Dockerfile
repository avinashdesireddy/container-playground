# escape=`

FROM mcr.microsoft.com/windows/servercore/iis as base
LABEL docker.image.base="mcr.microsoft.com/windows/servercore/iis" `
      docker.image.description="Dockerfile with IIS, IIS-WindowsAuthentication & Custom Ssl cert binded to app pool" `
      docker.image.build="docker build --build-arg CERT_PFX_FILENAME='cert.pfx' --build-arg CERT_PFX_PASSWORD='PASSWORD' --tag DTR_SERVER/microsoft/netcore-runtime:2.1-iis ."

## Install dotnet 2.1.2 hosting pack
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

ADD https://download.microsoft.com/download/1/f/7/1f7755c5-934d-4638-b89f-1f4ffa5afe89/dotnet-hosting-2.1.2-win.exe "C:/setup/dotnet-hosting-2.1.2-win.exe"
RUN start-process -Filepath "C:/setup/dotnet-hosting-2.1.2-win.exe" -ArgumentList @('/install', '/quiet', '/norestart') -Wait
RUN Remove-Item -Force "C:/setup/dotnet-hosting-2.1.2-win.exe"
## End Install dotnet 2.1.2 hosting pack

## Enabled IIS-WindowsAuthentication Module
RUN Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication,IIS-HttpRedirect,IIS-HttpLogging

WORKDIR /install

## --build-arg CERT_PFX_FILENAME='cert.pfx' --build-arg CERT_PFX_PASSWORD='PASSWORD'
ARG CERT_PFX_FILENAME
ARG CERT_PFX_PASSWORD

COPY ${CERT_PFX_FILENAME} .
## Create Web Site and Web Application with SSL
RUN Import-Module WebAdministration; `
    $appPool='app'; `
    Remove-Website -Name 'Default Web Site'; `
    New-WebAppPool -Name $appPool; `
    $mypwd = ConvertTo-SecureString -String $Env:CERT_PFX_PASSWORD -Force –AsPlainText; `
    $cert = Import-PfxCertificate –FilePath $Env:CERT_PFX_FILENAME cert:\localMachine\My -Password $mypwd; `
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList My, LocalMachine; `
    $rootStore.Open('MaxAllowed'); `
    $rootStore.Add($cert); `
    $rootStore.Close(); `
    cd iis:; `
    Set-ItemProperty IIS:\AppPools\$appPool -Name managedRuntimeVersion -Value ''; `
    Set-ItemProperty IIS:\AppPools\$appPool -Name processModel.identityType -Value NetworkService; `
    New-item -path IIS:\SslBindings\0.0.0.0!443 -value $cert; `
    New-Website -Name $appPool -Port 80 -PhysicalPath 'C:\app' -ApplicationPool $appPool -force; `
    New-WebBinding -Name $appPool -Port 443 -IP "*" -Protocol https

## Set Working directory
WORKDIR /app
## Cleanup files
RUN Remove-Item -Recurse -Force -Path /install
