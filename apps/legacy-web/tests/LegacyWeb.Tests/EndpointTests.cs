using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace LegacyWeb.Tests;

public class EndpointTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Health_returns_200_and_Healthy()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Version_reports_service_name()
    {
        var body = await _client.GetStringAsync("/version");

        Assert.Contains("legacy-web", body);
    }

    [Fact]
    public async Task Customer_lookup_returns_502_when_customer_api_is_unreachable()
    {
        // Nothing listens on the default BaseUrl in tests, so the dependency is down.
        var response = await _client.GetAsync("/api/orders/1/customer");

        Assert.True(
            response.StatusCode is HttpStatusCode.BadGateway or HttpStatusCode.GatewayTimeout,
            $"Unexpected status {response.StatusCode}");
    }
}
