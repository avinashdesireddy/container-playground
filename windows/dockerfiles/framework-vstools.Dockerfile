#escape=`

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8
LABEL docker.image=".NET FRAMEWORK with VS Tools" `
      docker.description="Dockerfile with VS Tools" `
      docker.base.image="mcr.microsoft.com/dotnet/framework/sdk:4.8" `
      docker.cmd.build=""
WORKDIR /src

ADD tools ./tools
COPY Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll .
RUN ./tools/gacutil /i Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll
