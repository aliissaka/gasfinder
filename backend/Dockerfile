FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY GasFinder.sln ./
COPY src/GasFinder.Api/GasFinder.Api.csproj                       src/GasFinder.Api/
COPY src/GasFinder.Domain/GasFinder.Domain.csproj                 src/GasFinder.Domain/
COPY src/GasFinder.Infrastructure/GasFinder.Infrastructure.csproj src/GasFinder.Infrastructure/
COPY src/GasFinder.Shared/GasFinder.Shared.csproj                 src/GasFinder.Shared/

RUN dotnet restore src/GasFinder.Api/GasFinder.Api.csproj

COPY src/ src/
RUN dotnet publish src/GasFinder.Api/GasFinder.Api.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "GasFinder.Api.dll"]
