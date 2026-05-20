FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Build context is the repo root so we can also pull in GasFinder.Shared.
COPY admin/GasFinder.Admin.csproj                          admin/
COPY backend/src/GasFinder.Shared/GasFinder.Shared.csproj  backend/src/GasFinder.Shared/

RUN dotnet restore admin/GasFinder.Admin.csproj

COPY admin/                          admin/
COPY backend/src/GasFinder.Shared/   backend/src/GasFinder.Shared/

RUN dotnet publish admin/GasFinder.Admin.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "GasFinder.Admin.dll"]
