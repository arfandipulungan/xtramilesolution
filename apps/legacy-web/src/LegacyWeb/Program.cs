using System.Reflection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"]);

// Cross-cloud dependency: the Azure .NET 8 Web API (customer-api) on the hot path.
// Target state: private hostname reached over the AWS <-> Azure private link, and an
// Entra token obtained via workload identity federation (no static API key).
builder.Services.AddHttpClient("customer-api", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["CustomerApi:BaseUrl"] ?? "http://localhost:5080");
    client.Timeout = TimeSpan.FromSeconds(5);
});

var app = builder.Build();

// Liveness: ALB target group health check and the CodeDeploy ValidateService hook.
app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});
app.MapHealthChecks("/health/ready");

app.MapGet("/version", () => Results.Ok(new
{
    service = "legacy-web",
    version = typeof(Program).Assembly
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "unknown"
}));

// Sample page logic that calls the shared business logic in Azure.
app.MapGet("/api/orders/{id:int}/customer", async (int id, IHttpClientFactory factory) =>
{
    try
    {
        var response = await factory.CreateClient("customer-api").GetAsync($"/api/customers/{id}");
        return response.IsSuccessStatusCode
            ? Results.Content(await response.Content.ReadAsStringAsync(), "application/json")
            : Results.StatusCode((int)response.StatusCode);
    }
    catch (HttpRequestException)
    {
        return Results.StatusCode(StatusCodes.Status502BadGateway);
    }
    catch (TaskCanceledException)
    {
        return Results.StatusCode(StatusCodes.Status504GatewayTimeout);
    }
});

app.Run();

public partial class Program { }
