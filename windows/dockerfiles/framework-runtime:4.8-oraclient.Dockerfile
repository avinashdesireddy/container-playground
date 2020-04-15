#escape=`

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8

LABEL docker.image.base="mcr.microsoft.com/dotnet/framework/aspnet:4.8" `
      docker.image.description="Dockerfile with Oracle CLI & Custom ssl cert binded to default website" `
      docker.image.build="docker build --build-arg CERT_PFX_FILENAME='cert.pfx' --build-arg CERT_PFX_PASSWORD='PASSWORD' --build-arg DTR_SERVER='' --tag DTR_SERVER/microsoft/framework-runtime:4.8-oraclient ."

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /install
COPY . .

## Install Oracle Cli
RUN Start-Process C:\install\oraclient_x64_12201\setup.exe -ArgumentList '-silent -nowait -responseFile C:\install\oraclient_x64_12201\setup.rsp -ignorePrereq -J"-Doracle.install.client.validate.clientSupportedOSCheck=false"' -NoNewWindow -Wait

## End Oracle Cli Install

## Adding new website for app
RUN Import-Module WebAdministration; `
    Remove-Website -Name 'Default Web Site'; `
    New-WebAppPool -Name 'app'; `
    Set-ItemProperty IIS:\AppPools\app -Name managedRuntimeVersion -Value 'v4.0'; `
    Set-ItemProperty IIS:\AppPools\app -Name processModel.identityType -Value NetworkService; `
    New-Website -Name 'app' `
                -Port 80 -PhysicalPath 'C:\app' `
                -ApplicationPool 'app' -force

## Enable SSL
## --build-arg CERT_PFX_FILENAME='cert.pfx' --build-arg CERT_PFX_PASSWORD='PASSORD'
ARG CERT_PFX_FILENAME
ARG CERT_PFX_PASSWORD

COPY ${CERT_PFX_FILENAME} .
RUN  Import-module webadministration; `
     $mypwd = ConvertTo-SecureString -String $Env:CERT_PFX_PASSWORD -Force –AsPlainText; `
     $cert = Import-PfxCertificate –FilePath $Env:CERT_PFX_FILENAME cert:\localMachine\My -Password $mypwd; `
     $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList My, LocalMachine; `
     $rootStore.Open('MaxAllowed'); `
     $rootStore.Add($cert); `
     $rootStore.Close(); `
     cd iis:; `
     New-item -path IIS:\SslBindings\0.0.0.0!443 -value $cert; `
     New-WebBinding -Name "app" -IP "*" -Port 443 -Protocol https
# End SSL


## Set Working directory
WORKDIR /app

## Cleanup files
RUN Remove-Item -Recurse -Force -Path /install
