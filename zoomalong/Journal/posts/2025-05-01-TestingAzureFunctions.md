---
layout: post
title: Integration Testing Azure Functions
categories: [Azure Functions, Testing]
image: /images/function-apps.png
author: "Gary Newport"
date: "2025/05/01"
---

Integration testing of azure functions is essential when demostrating that a service does what its supposed to do, and also responds in the way you expect.
This post shows how you can construct a unit test, in this case Specflow, so that it excutes the function as a background process, so that you can test it using standard http calls.

This process uses the Azure Functions Core Tools cli interface https://go.microsoft.com/fwlink/?linkid=2174087 which should be installed.
This should also be installed as part of the build process.
```yml
  - task: PowerShell@2
    inputs:
      targetType: 'inline'
      script: 'choco install azure-functions-core-tools -y'
```

This snippet demostrates how to instatiate the Azure function at the start of the unit test and kill it off after the test has completed.
N.B the Directory Info object you pass is the directory of your azure function source code.

```C#
namespace ImageResizerTests
{
    [Binding]
    public class ResizerSteps
    {
        private string request;
        private IFlurlResponse response;
        private static TemporaryAzureFunctionsApplication azfunc;

        [BeforeTestRun(Order = 1)]
        public static void Before()
        {
            var dirInfo = new DirectoryInfo("..\\..\\..\\..\\..\\src\\Application\\KnightFrank.Hub.Watermark");
            Console.WriteLine($"Directory : {dirInfo.ToString()}");

            azfunc = TemporaryAzureFunctionsApplication.StartNewAsync(dirInfo).Result;
        }

        [AfterTestRun]
        public static void After()
        {
            azfunc.DisposeAsync();
        }

        [When(@"the URI is evaluated")]
        public void WhenTheURIIsEvaluated()
        {
            try
            {
                response = "http://localhost:7071/api/Resize"
                    .WithHeader("Accept", "*/*")
                    .WithHeader("Content_Type", "application/json")
                    .AllowAnyHttpStatus()
                    .PostJsonAsync(new { Size = "SmallThumbnail", InputUri = request }).Result;
            }
            catch(Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }
    }
}
```

Copy the following into its own file, as is.

```C#
namespace ImageResizerTests
{
    using Polly;
    using Polly.Retry;
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Net.Http;
    using System.Threading.Tasks;

    public class TemporaryAzureFunctionsApplication : IAsyncDisposable
    {
        private readonly Process _application;
        private static readonly HttpClient HttpClient = new HttpClient();

        private TemporaryAzureFunctionsApplication(Process application)
        {
            _application = application;
        }

        public static async Task<TemporaryAzureFunctionsApplication> StartNewAsync(DirectoryInfo projectDirectory)
        {
            int port = 7071;
            Process app = StartApplication(port, projectDirectory);
            await WaitUntilTriggerIsAvailableAsync($"http://localhost:{port}/");

            return new TemporaryAzureFunctionsApplication(app);
        }

        private static Process StartApplication(int port, DirectoryInfo projectDirectory)
        {
            var appInfo = new ProcessStartInfo("func", $"start --port {port} --prefix bin/Debug/net8.0")
            {
                UseShellExecute = false,
                CreateNoWindow = false,
                WorkingDirectory = projectDirectory.FullName
            };

            var app = new Process { StartInfo = appInfo };
            app.Start();
            return app;
        }

        private static async Task WaitUntilTriggerIsAvailableAsync(string endpoint)
        {
            AsyncRetryPolicy retryPolicy =
                    Policy.Handle<Exception>()
                          .WaitAndRetryForeverAsync(index => TimeSpan.FromMilliseconds(500));

            PolicyResult<HttpResponseMessage> result =
                await Policy.TimeoutAsync(TimeSpan.FromSeconds(30))
                            .WrapAsync(retryPolicy)
                            .ExecuteAndCaptureAsync(() => HttpClient.GetAsync(endpoint));

            if (result.Outcome == OutcomeType.Failure)
            {
                throw new InvalidOperationException(
                    "The Azure Functions project doesn't seem to be running, "
                    + "please check any build or runtime errors that could occur during startup");
            }
        }

        public ValueTask DisposeAsync()
        {
            if (!_application.HasExited)
            {
                _application.Kill(entireProcessTree: true);
            }

            _application.Dispose();
            return ValueTask.CompletedTask;
        }
    }
}

```