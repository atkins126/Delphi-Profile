unit Delphi.Profile.CallInfo;

interface

type

  TCallInfo = class
    private
      FFunctionName: string;
      FTotalCalls  : Int64;
      FTotalTicks  : Int64;

      function GetTotalMicroseconds: Double;
      function GetAverageMicroseconds: Double;

    public
      constructor Create(const FunctionName: string);
      class function CommaHeader: string;
      function CommaText: string;

    public
      property TotalCalls         : Int64 read FTotalCalls write FTotalCalls;
      property TotalTicks         : Int64 read FTotalTicks write FTotalTicks;
      property TotalMicroseconds  : Double read GetTotalMicroseconds;
      property AverageMicroseconds: Double read GetAverageMicroseconds;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics;

constructor TCallInfo.Create(const FunctionName: string);
begin
  FFunctionName := FunctionName;
end;

class function TCallInfo.CommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Function', 'Total Calls', 'Total Time (us)', 'Average Time (us)']);
end;

function TCallInfo.CommaText: string;
const
  CTextFormat = '"%s","%d","%.1f","%.3f"';
begin
  Result := Format(CTextFormat, [FFunctionName, FTotalCalls, TotalMicroseconds, AverageMicroseconds]);
end;

function TCallInfo.GetTotalMicroseconds: Double;
begin
  Assert(TStopwatch.Frequency > 0);
  Result := FTotalTicks * 1000000.0 / TStopwatch.Frequency;
end;

function TCallInfo.GetAverageMicroseconds: Double;
begin
  Assert(FTotalCalls > 0);
  Result := TotalMicroseconds / FTotalCalls;
end;

end.
