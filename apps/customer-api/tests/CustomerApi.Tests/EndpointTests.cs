using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace CustomerApi.Tests;

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
    public async Task Readiness_returns_200()
    {
        var response = await _client.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Version_reports_service_name()
    {
        var body = await _client.GetStringAsync("/version");

        Assert.Contains("customer-api", body);
    }

    [Theory]
    [InlineData(1, HttpStatusCode.OK)]
    [InlineData(0, HttpStatusCode.NotFound)]
    public async Task Customer_lookup(int id, HttpStatusCode expected)
    {
        var response = await _client.GetAsync($"/api/customers/{id}");

        Assert.Equal(expected, response.StatusCode);
    }
}
