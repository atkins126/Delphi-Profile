unit Delphi.Profile.PerformanceCounter;

interface

type

  TPerformanceMetrics = record
    FElapsedTicks: Int64;
    // TODO: add other metrics (memory, etc.)
  end;

  TPerformanceCounter = class
    private
      class threadvar FStartTime: Int64;

    public
      class procedure Start;
      class function GetMetrics: TPerformanceMetrics;
      class function GetMicroseconds(ATicks: Int64): Double;
  end;

implementation

uses
  System.Diagnostics;

{ TPerformanceCounter }

class procedure TPerformanceCounter.Start;
begin
  FStartTime := TStopwatch.GetTimeStamp;
  // TODO: acquire other metrics in decreasing order of priority
end;

class function TPerformanceCounter.GetMetrics: TPerformanceMetrics;
begin
  Result.FElapsedTicks := TStopwatch.GetTimeStamp - FStartTime;
  // TODO: acquire other metrics in decreasing order of priority
end;

class function TPerformanceCounter.GetMicroseconds(ATicks: Int64): Double;
begin
  Assert(TStopwatch.Frequency > 0);
  Result := ATicks * 1000000.0 / TStopwatch.Frequency;
end;

initialization

TStopwatch.Create; // initialize the stopwatch type

end.
