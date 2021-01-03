unit Delphi.Profile.CallInfo;

interface

type

  TCallInfo = class
    private
      FScopeName : string;
      FTotalCalls: Int64;
      FTotalTicks: Int64;

      function GetTotalMicroseconds: Double; inline;
      function GetAverageMicroseconds: Double; inline;
      class function GetCommaHeader: string; inline; static;
      function GetCommaText: string; inline;

    public
      constructor Create(const AScopeName: string);

      class property CommaHeader: string read GetCommaHeader;
      property CommaText: string read GetCommaText;
      property TotalCalls: Int64 read FTotalCalls write FTotalCalls;
      property TotalTicks: Int64 read FTotalTicks write FTotalTicks;
      property TotalMicroseconds: Double read GetTotalMicroseconds;
      property AverageMicroseconds: Double read GetAverageMicroseconds;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics;

{ TCallInfo }

constructor TCallInfo.Create(const AScopeName: string);
begin
  FScopeName := AScopeName;
end;

class function TCallInfo.GetCommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Function', 'Total Calls', 'Total Time (us)', 'Average Time (us)']);
end;

function TCallInfo.GetCommaText: string;
const
  CTextFormat = '"%s","%d","%.1f","%.3f"';
begin
  Result := Format(CTextFormat, [FScopeName, FTotalCalls, GetTotalMicroseconds, GetAverageMicroseconds]);
end;

function TCallInfo.GetTotalMicroseconds: Double;
begin
  Assert(TStopwatch.Frequency > 0);
  Result := FTotalTicks * 1000000.0 / TStopwatch.Frequency;
end;

function TCallInfo.GetAverageMicroseconds: Double;
begin
  Assert(FTotalCalls > 0);
  Result := GetTotalMicroseconds / FTotalCalls;
end;

initialization

TStopwatch.Create; // initialize the stopwatch type

end.
