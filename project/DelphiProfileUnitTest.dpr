program DelphiProfileUnitTest;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  FastMM4,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.JUnit,
  DUnitX.StackTrace.JCL,
  {$ENDIF }
  DUnitX.TestFramework,
  Delphi.Profile.TraceTest in '..\test\Delphi.Profile.TraceTest.pas',
  Delphi.Profile.ScopeInfoTest in '..\test\Delphi.Profile.ScopeInfoTest.pas',
  Delphi.Profile.AggregateInfoTest in '..\test\Delphi.Profile.AggregateInfoTest.pas',
  Delphi.Profile.AggregateReportTest in '..\test\Delphi.Profile.AggregateReportTest.pas',
  Delphi.Profile.PerformanceReportTest in '..\test\Delphi.Profile.PerformanceReportTest.pas',
  Delphi.Profile.PerformanceTracerTest in '..\test\Delphi.Profile.PerformanceTracerTest.pas',
  Delphi.Profile.PerformanceCounterTest in '..\test\Delphi.Profile.PerformanceCounterTest.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  junitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an JUnit compatible XML File
    junitLogger := TDUnitXXMLJUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(junitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
