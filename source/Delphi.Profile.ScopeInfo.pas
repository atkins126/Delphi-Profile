unit Delphi.Profile.ScopeInfo;

interface

type

  TScopeInfo = class
    private
      FScopeName : string;
      FTotalHits : Int64;
      FTotalTicks: Int64;

      function GetTotalMicroseconds: Double;
      function GetAverageMicroseconds: Double; inline;
      class function GetCommaHeader: string; static;
      function GetCommaText: string;

    public
      constructor Create(const AScopeName: string);

      class property CommaHeader: string read GetCommaHeader;
      property CommaText: string read GetCommaText;
      property TotalHits: Int64 read FTotalHits write FTotalHits;
      property TotalTicks: Int64 read FTotalTicks write FTotalTicks;
      property TotalMicroseconds: Double read GetTotalMicroseconds;
      property AverageMicroseconds: Double read GetAverageMicroseconds;
  end;

implementation

uses
  Delphi.Profile.PerformanceCounter,
  System.SysUtils;

{ TScopeInfo }

constructor TScopeInfo.Create(const AScopeName: string);
begin
  FScopeName := AScopeName;
end;

class function TScopeInfo.GetCommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Scope Name', 'Total Hits', 'Total Time (us)', 'Average Time (us)']);
end;

function TScopeInfo.GetCommaText: string;
const
  CTextFormat = '"%s","%d","%.1f","%.3f"';
begin
  Result := Format(CTextFormat, [FScopeName, FTotalHits, GetTotalMicroseconds, GetAverageMicroseconds]);
end;

function TScopeInfo.GetTotalMicroseconds: Double;
begin
  Result := TPerformanceCounter.GetMicroseconds(FTotalTicks);
end;

function TScopeInfo.GetAverageMicroseconds: Double;
begin
  Assert(FTotalHits > 0);
  Result := GetTotalMicroseconds / FTotalHits;
end;

end.
