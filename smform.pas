unit sMForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, IdHTTP,
  IdSSLOpenSSL;

type

  { TMForm }

  TMForm = class(TForm)
    Button1: TButton;
    EditAPIKey: TEdit;
    EditSummoner: TEdit;
    HTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    LabelSummonerLevel: TLabel;
    LabelSummonerID: TLabel;
    MemoLog: TMemo;
    ToggleBox1: TToggleBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private
    function GetAPIKeyAsParameter(): String;
    function LogChampionData(JsonStr: String): Boolean;
    function GetSummonerData(JsonStr: String; var SummonerID, SummonerIdOfKey, SummonerLevel: String): Boolean;
    procedure ShowError(Msg: String);
    procedure Log(s: String);
    procedure DownloadInfo(SummonerName: String);
  public

  end;

const
  RiotApiHostName = 'eun1.api.riotgames.com';
  RiotApiPortNumber = 443;
  LoLBaseURL = 'https://' + RiotApiHostName + '/lol/';


var
  MForm: TMForm;

implementation

{$R *.lfm}

{ TMForm }

uses fpjson, jsonparser;


function TMForm.GetSummonerData(JsonStr: String; var SummonerID, SummonerIdOfKey, SummonerLevel: String): Boolean;
var
  b: Boolean;
  jObject: TJSONObject;
  jData: TJSONData;
begin

  b := False;

  try

    jData := GetJSON(JsonStr);

    jObject := TJSONObject(jData);

    SummonerID := jObject.Get('profileIconId');

    SummonerIDOfKey := jObject.Get('id');

    SummonerLevel := jObject.Get('summonerLevel');

    b := True;

  except
    // trap
  end;

  Result := b;

end;


function TMForm.GetAPIKeyAsParameter(): String;
begin

  Result := '?api_key=' + EditAPIKey.Text;

end;

procedure TMForm.ShowError(Msg: String);
begin

  MessageDlg('Error', Msg, mtError, [mbOK], 0);

end;


procedure TMForm.Log(s: String);
begin

  MemoLog.Lines.Append(s);

end;


function TMForm.LogChampionData(JsonStr: String):Boolean;
var
  b: Boolean;
  jObject: TJSONObject;
  jData: TJSONData;
  jArray: TJSONArray;
  i: Integer;
  ChampionId, ChampionLevel, ChampionPoints: String;
begin

  b := False;

  try

    jData := GetJSON(JsonStr);

    jArray := TJSONArray(jData);

    for i := 0 to jArray.Count - 1 do
      begin

        jObject := TJsonObject(jArray.Items[i]);

        ChampionId := jObject.Get('championId');

        ChampionLevel := jObject.Get('championLevel');

        ChampionPoints := jObject.Get('championPoints');

        Log('Champion: ' + ChampionId + ', ' + #9 +
            'Lvl: ' + ChampionLevel + ', ' + #9 +
            'Points: ' + ChampionPoints);

      end;

    b := True;

  except
    // trap
  end;

  Result := b;

end;


procedure TMForm.DownloadInfo(SummonerName: String);
const
  SummonerEndpoint = 'summoner/v4/summoners/by-name/';
  ChampionEndpoint = 'champion-mastery/v4/champion-masteries/by-summoner/';
var
  Content: String;
  SummonerID, SummonerIDofKey, SummonerLevel: String;
  s: String;
begin

  try

    Screen.Cursor := crHourGlass;

    HTTP1.Connect(RiotApiHostName, RiotApiPortNumber);
    try

      Log('Connected to RIOT API server.');

      Content := HTTP1.Get(LoLBaseURL + SummonerEndpoint + SummonerName + getAPIKeyAsParameter());

      Log('Received data.');

      if (GetSummonerData(Content, SummonerID, SummonerIDofKey, SummonerLevel)) then
        begin

          //MemoLog.Lines.Append(Content);   // dump data

          Log('Summoner data parsed.');

          LabelSummonerID.Caption := SummonerID;

          LabelSummonerLevel.Caption := SummonerLevel;

          Log('Downloading champion data');

          s := LoLBaseURL + ChampionEndpoint + SummonerIDOfKey + getAPIKeyAsParameter();

          Content := HTTP1.Get(s);

          if (LogChampionData(Content)) then
            begin

              Log('End of champion data.');

            end
          else
            begin

              Log('Data is corrupt');

            end;

        end
      else
        begin

          Log('Data is corrupt.');

        end;

    finally

      Screen.Cursor := crDefault;

      HTTP1.Disconnect;

      Log('Disconnected from RIOT API server.');

    end;

  except

    Log('Failed to connect to RIOT API server.');

    ShowError('Communication error or wrong API key.');

  end;

end;

procedure TMForm.Button1Click(Sender: TObject);
begin

  if (trim(EditSummoner.Text) <> '') then
    begin

      DownloadInfo(EditSummoner.Text);

    end
  else
    begin

      ShowError('Summoner ID shall not be empty.');

    end;

end;

procedure TMForm.FormCreate(Sender: TObject);
begin

end;


procedure TMForm.ToggleBox1Change(Sender: TObject);
begin

  Application.Terminate;

end;


end.

