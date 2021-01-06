unit Delphi.Profile.PerformanceMetrics;

interface

type

  TPerformanceMetrics = record
    private
      class var FFrequency: Int64; // set once during program initialization

    private
      FRealTime: Int64;
      FCpuTime : UInt64;

      function GetMicroseconds: Double;

    public
      procedure AcquireStart; // acquires real-time before cpu-time
      procedure AcquireEnd;   // acquires real-time after cpu-time
      procedure Add(const AMetrics: TPerformanceMetrics);
      procedure Subtract(const AMetrics: TPerformanceMetrics);
      function Compare(const AMetrics: TPerformanceMetrics): Integer;

      property RealTime: Int64 read FRealTime;
      property CpuTime: UInt64 read FCpuTime;
      property Microseconds: Double read GetMicroseconds;
  end;

implementation

uses
  System.Classes,
  Winapi.Windows;

{ TPerformanceMetrics }

procedure TPerformanceMetrics.AcquireStart;
begin
  Assert(QueryThreadCycleTime(TThread.Current.Handle, FCpuTime));
  Assert(QueryPerformanceCounter(FRealTime));
end;

procedure TPerformanceMetrics.AcquireEnd;
begin
  Assert(QueryPerformanceCounter(FRealTime));
  Assert(QueryThreadCycleTime(TThread.Current.Handle, FCpuTime));
end;

procedure TPerformanceMetrics.Add(const AMetrics: TPerformanceMetrics);
begin
  Inc(FRealTime, AMetrics.FRealTime);
  Inc(FCpuTime, AMetrics.FCpuTime);
end;

function TPerformanceMetrics.Compare(const AMetrics: TPerformanceMetrics): Integer;
begin
  if FRealTime < AMetrics.FRealTime then
    Result := - 1
  else if FRealTime > AMetrics.FRealTime then
    Result := 1
  else
    Result := 0;
end;

procedure TPerformanceMetrics.Subtract(const AMetrics: TPerformanceMetrics);
begin
  Dec(FRealTime, AMetrics.FRealTime);
  Dec(FCpuTime, AMetrics.FCpuTime);
end;

function TPerformanceMetrics.GetMicroseconds: Double;
const
  CMicroPerSecond = 1E6;
begin
  Result := CMicroPerSecond * FRealTime / FFrequency;
end;

initialization

Assert(QueryPerformanceFrequency(TPerformanceMetrics.FFrequency));

end.
