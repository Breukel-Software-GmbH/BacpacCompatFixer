# ====================================================
# BacpacCompatFixer - Container (Linux)
# ====================================================
# Multi-Stage Build für optimale Image-Größe
# Target: Azure App Service (Linux Container)
# ====================================================

# ==================== BUILD STAGE ====================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Clean nuget.config für Docker (keine Windows-Pfade)
RUN printf '<?xml version="1.0" encoding="utf-8"?>\n<configuration>\n  <packageSources>\n    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />\n    <add key="github" value="https://nuget.pkg.github.com/Breukel-Software-GmbH/index.json" />\n  </packageSources>\n</configuration>' > nuget.config

COPY Directory.Build.props Directory.Packages.props ./
COPY src/BacpacCompatFixer.Blazor/BacpacCompatFixer.Blazor.csproj src/BacpacCompatFixer.Blazor/
COPY src/BacpacCompatFixer.Core/BacpacCompatFixer.Core.csproj src/BacpacCompatFixer.Core/
RUN dotnet restore src/BacpacCompatFixer.Blazor/BacpacCompatFixer.Blazor.csproj --configfile nuget.config

# Erst hier den Rest kopieren (.dockerignore hält bin/obj aus dem Image fern,
# sonst überschreibt der Host-obj die Restore-Ausgabe mit Windows-Pfaden).
COPY src/ src/

WORKDIR /src/src/BacpacCompatFixer.Blazor
RUN dotnet publish BacpacCompatFixer.Blazor.csproj -c Release -o /app/publish --self-contained false -p:UseAppHost=false

# ==================== RUNTIME STAGE ====================
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .

EXPOSE 8080

ENTRYPOINT ["dotnet", "BacpacCompatFixer.Blazor.dll"]
