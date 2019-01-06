/*
	description:
	 - New network system handler.
	destination:
	 - Nil: Everyone
	 - String: vehicleVarName of the unit to trigger on.
	 - Side: A side
	note:
	 - addPublicVariableEventHandler is triggered everywhere BUT on the caller.
	usage:
	 - [destination,client PVF to run,parameters]
*/

Private ["_destination","_exit","_parameters","_publicVar","_script"];
_destination = _this select 0; //WTF error!!!????

//_publicVar = _this;
_exit = true;

if (isNil '_destination') then {_destination = 0;_exit = false};
if (typeName(_destination) == 'SIDE') then {if (sideJoined == _destination) then {_exit = false}};
if (typeName(_destination) == 'STRING') then {
	if (vehicleVarName player == _destination) then {_exit = false};
};

if (_exit) exitWith {};

_script = _this select 1;
_parameters = if (count _this > 2) then {_this select 2} else {[]};

_parameters Spawn (Call Compile _script);