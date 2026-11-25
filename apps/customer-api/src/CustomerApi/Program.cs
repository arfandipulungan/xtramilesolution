using System.Reflection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// "live" = the process is up. Add real dependency checks (SQL, Key Vault, Service Bus)
// without the "live" tag so they only affect /health/ready.
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"]);

var app = builder.Build();

// Liveness: used by the pipeline smoke test and the App Service Health check setting.
app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});

// Readiness: every registered check.
app.MapHealthChecks("/health/ready");

// Shows which release is live (the pipeline stamps the version at publish time),
// handy when correlating an incident with a deployment.
app.MapGet("/version", () => Results.Ok(new
{
    service = "customer-api",
    version = typeof(Program).Assembly
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "unknown"
}));

// Sample business endpoint standing in for the shared logic the AWS tier calls.
app.MapGet("/api/customers/{id:int}", (int id) =>
    id > 0
        ? Results.Ok(new { id, name = $"Customer {id}", tier = "standard" })
        : Results.NotFound());

app.Run();

// Makes Program visible to WebApplicationFactory in the test project.
public partial class Program { }
