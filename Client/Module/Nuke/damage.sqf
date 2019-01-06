//--- Nuke destruction.
Private ["_array","_array2","_blackListed","_bo","_destroy","_target","_z"];
diag_log "Nuke splash";

//[] Spawn PostNuclearEffects;
[[[],"Client\Module\Nuke\post_nuclear_effects.sqf"],"BIS_fnc_execVM",true,true] call BIS_fnc_MP;
NuclearStrike = true;

_target = _this select 0;
//_array = _target nearObjects [[], 2000];
_array = nearestObjects [_target, ["All"], 2000];

_blackListed = WFDepot + WFCAMP + ["Land_Barrack2_EP1","land_nav_pier_c","land_nav_pier_c2","land_nav_pier_c2_end","land_nav_pier_c_270","land_nav_pier_c_90","land_nav_pier_c_big","land_nav_pier_C_L","land_nav_pier_C_L10","land_nav_pier_C_L30","land_nav_pier_C_R","land_nav_pier_C_R10","land_nav_pier_C_R30","land_nav_pier_c_t15","land_nav_pier_c_t20","land_nav_pier_F_17","land_nav_pier_F_23","land_nav_pier_m","land_nav_pier_m_1","land_nav_pier_m_end","land_nav_pier_M_fuel","land_nav_pier_pneu","land_nav_pier_uvaz"];
_destroy = _array;
{if ((typeOf _x) in _blackListed) then {_destroy = _destroy - [_x]}} forEach _array;
{_x setdammage 1} forEach _destroy; // Markus - fixed this clusterfuck of spam.

[_target] Spawn {
	Private ["_array","_dammageable","_dammages","_range","_target"];
	_target = _this select 0;
	_dammageable = ["Man","Car","Motorcycle","Tank","Ship","Air","StaticWeapon"];
	_range = 1500;
	_dammages = 0.2;
	for [{_z = 0},{_z < 4},{_z = _z + 1}] do {
		_array = _target nearEntities [_dammageable, _range];
		{
			if (_x isKindOf "Man") then {_x setDammage (getDammage _x + _dammages)};
			{_x setDammage  (getDammage _x + _dammages)} forEach crew _x;
		} forEach _array;
		_range = _range + 300;
		_dammages = _dammages - 0.2;
		sleep 10;
	};
	//--- Radiations.
	[_target] Spawn NukeRadiation;
};