unit Delphi.Profile.PerformanceCounter;

interface

{$IFDEF MSWINDOWS}


uses
  System.SyncObjs;
{$ENDIF}


type

  TPerformanceMetrics = record
    FRealClockTime: Int64;
    // TODO: add memory metrics
    FUserModeTime: Uint64;
    FKernelModeTime: Uint64;
    FThreadCount: Uint32;
    FHandleCount: Uint32;
    FOtherOperationCount: Uint64;
    FOtherTransferCount: Uint64;
    FReadOperationCount: Uint64;
    FReadTransferCount: Uint64;
    FWriteOperationCount: Uint64;
    FWriteTransferCount: Uint64;
{$IFDEF MSWINDOWS}
    procedure Initialize(AWin32Process: OLEVariant);
{$ENDIF}
    procedure Subtract(const AMetrics: TPerformanceMetrics);
  end;

  TPerformanceCounter = class
    private
      class threadvar FStartMetrics: TPerformanceMetrics;
      class var FEnableWmi         : Boolean;
      class procedure GetCurrentMetrics(var AMetrics: TPerformanceMetrics);
    public
      class property EnableWmi: Boolean write FEnableWmi;
      class procedure Start;
      class function GetElapsedMetrics: TPerformanceMetrics;
      class function GetMicroseconds(ATicks: Int64): Double;
  end;

{$IFDEF MSWINDOWS}

  TWmiCounter = class
    private
      class var FService: OLEVariant; // set once during program initialization
      class var FQuery  : string;
      class var FMutex  : TCriticalSection;
      class function ExecuteQuery: OLEVariant;
      class procedure Finalize;
      class procedure Initialize;
  end;
{$ENDIF}

implementation

uses
{$IFDEF MSWINDOWS}
  System.SysUtils,
  Winapi.ActiveX,
  Winapi.Windows,
  System.Win.ComObj,
  System.Variants,
{$ENDIF}
  System.Diagnostics;

{ TPerformanceMetrics }

{$IFDEF MSWINDOWS}


procedure TPerformanceMetrics.Initialize(AWin32Process: OLEVariant);
begin
  FUserModeTime        := AWin32Process.UserModeTime;
  FKernelModeTime      := AWin32Process.KernelModeTime;
  FThreadCount         := AWin32Process.ThreadCount;
  FHandleCount         := AWin32Process.HandleCount;
  FOtherOperationCount := AWin32Process.OtherOperationCount;
  FOtherTransferCount  := AWin32Process.OtherTransferCount;
  FReadOperationCount  := AWin32Process.ReadOperationCount;
  FReadTransferCount   := AWin32Process.ReadTransferCount;
  FWriteOperationCount := AWin32Process.WriteOperationCount;
  FWriteTransferCount  := AWin32Process.WriteTransferCount;
end;
{$ENDIF}


procedure TPerformanceMetrics.Subtract(const AMetrics: TPerformanceMetrics);
begin
  Dec(FRealClockTime, AMetrics.FRealClockTime);
  Dec(FUserModeTime, AMetrics.FUserModeTime);
  Dec(FKernelModeTime, AMetrics.FKernelModeTime);
  Dec(FThreadCount, AMetrics.FThreadCount);
  Dec(FHandleCount, AMetrics.FHandleCount);
  Dec(FOtherOperationCount, AMetrics.FOtherOperationCount);
  Dec(FOtherTransferCount, AMetrics.FOtherTransferCount);
  Dec(FReadOperationCount, AMetrics.FReadOperationCount);
  Dec(FReadTransferCount, AMetrics.FReadTransferCount);
  Dec(FWriteOperationCount, AMetrics.FWriteOperationCount);
  Dec(FWriteTransferCount, AMetrics.FWriteTransferCount);
end;

{ TPerformanceCounter }

class procedure TPerformanceCounter.Start;
begin
  GetCurrentMetrics(FStartMetrics);
  FStartMetrics.FRealClockTime := TStopwatch.GetTimeStamp;
end;

class procedure TPerformanceCounter.GetCurrentMetrics(var AMetrics: TPerformanceMetrics);
begin
{$IFDEF MSWINDOWS}
  if FEnableWmi then
    AMetrics.Initialize(TWmiCounter.ExecuteQuery);
{$ENDIF}
  // TODO: acquire memory metrics
end;

class function TPerformanceCounter.GetElapsedMetrics: TPerformanceMetrics;
begin
  Result.FRealClockTime := TStopwatch.GetTimeStamp;
  GetCurrentMetrics(FStartMetrics);
  // TODO: acquire memory metrics
  Result.Subtract(FStartMetrics);
end;

class function TPerformanceCounter.GetMicroseconds(ATicks: Int64): Double;
begin
  Assert(TStopwatch.Frequency > 0);
  Result := ATicks * 1000000.0 / TStopwatch.Frequency;
end;

{$IFDEF MSWINDOWS}


class function TWmiCounter.ExecuteQuery: OLEVariant;
const
  CWbemFlagForwardOnly = $00000020;
var
  WbemObjectSet: OLEVariant;
  oEnum        : IEnumvariant;
begin
  FMutex.Acquire;
  try
    WbemObjectSet := FService.ExecQuery(FQuery, 'WQL', CWbemFlagForwardOnly);
    oEnum         := IUnknown(WbemObjectSet._NewEnum) as IEnumvariant;
    Assert(oEnum.Next(1, Result, PLongWord(nil)^) = S_OK);
  finally
    FMutex.Release;
  end;
end;

class procedure TWmiCounter.Initialize;
const
  CWbemLocatorName = 'WbemScripting.SWbemLocator';
  CWbemUser        = '';
  CWbemPassword    = '';
  CWbemComputer    = 'localhost';
  CWbemNamespace   = 'root\CIMV2';
  CWmiQueryFormat  = 'SELECT * FROM Win32_Process WHERE ProcessId = %d';
var
  WbemLocator: OLEVariant;
begin
  CoInitialize(nil);
  WbemLocator := CreateOleObject(CWbemLocatorName);
  FService    := WbemLocator.ConnectServer(CWbemComputer, CWbemNamespace, CWbemUser, CWbemPassword);
  FQuery      := Format(CWmiQueryFormat, [GetCurrentProcessId]);
  FMutex      := TCriticalSection.Create;
end;

class procedure TWmiCounter.Finalize;
begin
  FMutex.Free;
  FService := Unassigned;
  CoUninitialize;
end;
{$ENDIF}

initialization

TStopwatch.Create;

{$IFDEF MSWINDOWS}
TWmiCounter.Initialize;

finalization

TWmiCounter.Finalize;
{$ENDIF}

end.
