{ Debug Subsystem

  08/2012 XE2 kompatibel
  02/2016 XE10 x64 Test
  xx/xxxx FPC Ubuntu

  --------------------------------------------------------------------
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY

  Author: Peter Lorenz
  Is that code useful for you? Donate!
  Paypal webmaster@peter-ebe.de
  --------------------------------------------------------------------

}

{$I ..\share_settings.inc}
unit debug_unit;

interface

uses
{$IFNDEF FPC}System.UITypes, {$ENDIF}
{$IFNDEF UNIX}Windows, {$ENDIF}
{$IFDEF FPC}LCLIntf, LCLType, LMessages, {$ENDIF}
  SyncObjs,
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

{ handling }
function debug_init(const proginf: string; path: string): boolean;
function debug_done(const closedgracefully: boolean): boolean;

function debug_istaktiv: boolean;

{ schreiben }
procedure debug_add(const debuginf: string);

{ lesen }
function debug_hasdump:boolean;
function debug_dump: string;

resourcestring
  rsdebuginitstarterror = 'Debug_Init konnte nicht gestartet werden!';
  rsdebuginiterror = 'Debug_Init Fehler!';
  rsdebugdoneerror = 'Debug_Done Fehler!';
  rsdebugdoneerrorfile = 'Debug_Done Fehler beim Löschen der Debugdatei!';

implementation

{ -------------------------------------------------------- }
type
  debugdateityp = byte;

const
  debugdateiname: string = 'debug.tmp';

const
  cr: byte = 13;
  lf: byte = 10;

  tr: byte = 00; // Nullterminierung

  { -------------------------------------------------------- }
var
  criticalsection_debug: SyncObjs.TCriticalSection;

  debugaktiv: boolean = false;
  debugpfad: string;
  debugproginf: string;

  debugaktionenindex, debugaktionennr: integer;
  debugaktionen: array [0 .. 4] of string;

  debugdateioffen: boolean = false;
  debugdatei: file of debugdateityp;
  debugdateibuf: array [0 .. 1024 * 10] of debugdateityp;

  { -------------------------------------------------------- }

function debug_init(const proginf: string; path: string): boolean;
var
  i: integer;
begin
  Result := false;

  try
    criticalsection_debug.Enter;

    { ggf. schließen (aber nicht löschen!
      sonst werden beim init nach einem crash die lezten ereignisse überschrieben)
    }
    if not debug_done(false) then
    begin
      messagedlg(rsdebuginitstarterror, mtwarning, [mbok], 0);
      exit;
    end;

    { preset }
    if length(path) < 1 then
      exit;
    debugaktiv := false;
    debugpfad := '';
    debugproginf := '';
    debugaktionennr := 0;
    debugaktionenindex := -1;
    for i := low(debugaktionen) to high(debugaktionen) do
      debugaktionen[i] := '-';
    debugdateioffen := false;

    { proginf merken }
    debugproginf := proginf;

    { pfad merken }
    path := IncludeTrailingPathDelimiter(path);
    debugpfad := path;

    try
      assignfile(debugdatei, debugpfad + debugdateiname);
      if fileexists(debugpfad + debugdateiname) then
        reset(debugdatei)
      else
        rewrite(debugdatei);
      debugdateioffen := true;
    except
      on e: exception do
      begin
        messagedlg(rsdebuginiterror + #13 + e.message, mtwarning, [mbok], 0);
        exit;
      end;
    end;
    debugaktiv := true;

  finally
    criticalsection_debug.Release;
  end;

  Result := true;
end;

function debug_done(const closedgracefully: boolean): boolean;
begin
  Result := false;

  try
    criticalsection_debug.Enter;

    try
      if debugdateioffen = true then
        closefile(debugdatei);
    except
      on e: exception do
      begin
        messagedlg(rsdebugdoneerror + #13 + e.message, mtwarning, [mbok], 0);
        exit;
      end;
    end;
    debugdateioffen := false;

    try
      if closedgracefully = true then
      begin
        if fileexists(debugpfad + debugdateiname) then
        begin
          if not deletefile(debugpfad + debugdateiname) then
          begin
            messagedlg(rsdebugdoneerrorfile, mtwarning, [mbok], 0);
            exit;
          end;
        end;
      end;
    except
      on e: exception do
      begin
        messagedlg(rsdebugdoneerror + #13 + e.message, mtwarning, [mbok], 0);
        exit;
      end;
    end;

  finally
    criticalsection_debug.Release;
  end;

  Result := true;
end;

function debug_istaktiv: boolean;
begin
  Result := debugaktiv;
end;

procedure debug_add(const debuginf: string);
var
  ausgabezeile: string;
  i, c: integer;
begin
  if debugaktiv = false then
    exit;
  if debugdateioffen = false then
    exit;

  try
    criticalsection_debug.Enter;

    try
      { fortlaufende Nummer um Reihenfolge der Aktionen zu sehen }
      inc(debugaktionennr);
      if (debugaktionennr = maxlongint) or (debugaktionennr < 0) then
        debugaktionennr := 0;

      { Array mit Schreibindex (ringbuffer, das geht schneller, deshalb die nummer mit der reihenfolge }
      inc(debugaktionenindex);
      if debugaktionenindex > high(debugaktionen) then
        debugaktionenindex := low(debugaktionen);
      debugaktionen[debugaktionenindex] := formatdatetime('dd.mm.yyyy hh:nn:ss',
        date + time) + ' (' + inttostr(debugaktionennr) + ')> ' + debuginf;

      { Schreibbuffer vorbereiten (erst einmal als String) }
      ausgabezeile := debugproginf + chr(cr) + chr(lf) + 'letzte aktion: ' +
        debuginf + chr(cr) + chr(lf) + '->letzte Aktionen' + chr(cr) + chr(lf);
      for i := low(debugaktionen) to high(debugaktionen) do
        ausgabezeile := ausgabezeile + debugaktionen[i] + chr(cr) + chr(lf);
      ausgabezeile := ausgabezeile + '<-letzte Aktionen' + chr(cr) + chr(lf) +
        '(EOF)' + chr(tr) + chr(tr);
      // Nullterminierung (hier wird beim Lesen gestoppt)

      { Daten in Datei schreiben (als Dateibuffer) }
      seek(debugdatei, 0);
      c := length(ausgabezeile);
      if c > high(debugdateibuf) then
        c := high(debugdateibuf);
      for i := 1 to length(ausgabezeile) do
        debugdateibuf[i - 1] := ord(ausgabezeile[i]);
      blockwrite(debugdatei, debugdateibuf, c);
    except
      on e: exception do
      begin
        { exeption im Debug - ignorieren }
      end;
    end;

  finally
    criticalsection_debug.Release;
  end;

end;

function debug_hasdump:boolean;
begin
  Result:= false;
  try
    criticalsection_debug.Enter;
    Result:= FileSize(debugdatei) > 0;
  finally
    criticalsection_debug.Release;
  end;
end;

function debug_dump: string;
var
  fs, readbytes, i: integer;
begin
  Result := '';

  try
    criticalsection_debug.Enter;

    if debugaktiv = false then
    begin
      debug_dump := 'debugdump fehler: debug nicht aktiv!';
      exit;
    end;
    if debugdateioffen = false then
    begin
      debug_dump := 'debugdump fehler: debugdatei nicht offen!';
      exit;
    end;

    try
      { inhalt der debugdatei zurückgeben }
      seek(debugdatei, 0);
      fs := filesize(debugdatei);
      if fs > sizeof(debugdateibuf) then
        fs := sizeof(debugdateibuf);
      blockread(debugdatei, debugdateibuf, fs, readbytes);
      if readbytes > 0 then
      begin
        Result := '';
        i := 0;
        repeat
          ;
          Result := Result + chr(debugdateibuf[i]);
          inc(i);
        until (i >= fs) or (debugdateibuf[i] = tr);
      end;

    except
      on e: exception do
      begin
        Result := 'debug_dump exception: ' + e.message;
      end;
    end;

  finally
    criticalsection_debug.Release;
  end;

end;

initialization

criticalsection_debug := SyncObjs.TCriticalSection.Create;

finalization

if assigned(criticalsection_debug) then
  FreeAndNil(criticalsection_debug);

end.
