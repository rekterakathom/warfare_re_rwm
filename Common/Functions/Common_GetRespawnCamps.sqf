Private ['_availableSpawn','_camps','_closestCamp','_deathLoc','_enemySide','_get','_hostiles','_nearestCamps','_respawnCampsMode','_respawnCampsRuleMode','_respawnMinRange','_side','_town','_townSID'],;

_deathLoc = _this select 0;
_side = _this select 1;

_availableSpawn = [];
_respawnCampsMode = 'WFBE_RESPAWNCAMPSMODE' Call GetNamespace;
_respawnCampsRuleMode = 'WFBE_RESPAWNCAMPSRULEMODE' Call GetNamespace;
_respawnMinRange = 'WFBE_RESPAWNMINRANGE' Call GetNamespace;


switch (_respawnCampsMode) do {
	case 1: {
		/* Classic Respawn */
		_town = [_deathLoc] Call GetClosestLocation;
		if !(isNull _town) then {
			if (_town distance _deathLoc  < ('WFBE_RESPAWNRANGE' Call GetNamespace)) then {
				_camps = [_town,_side] Call GetFriendlyCamps;
				if (count _camps > 0) then {
					if (_respawnCampsRuleMode > 0) then {
						_closestCamp = ([_deathLoc,_camps] Call SortByDistance) select 0;
						_enemySide = if (_side == west) then {[east]} else {[west]};
						if (_respawnCampsRuleMode == 2) then {_enemySide = _enemySide + [resistance]};
						_hostiles = [_closestCamp,_enemySide,_respawnMinRange] Call GetHostilesInArea;
						if (_deathLoc distance _closestCamp < _respawnMinRange && _hostiles > 0) then {_camps = _camps - [_closestCamp]};
					};
					_availableSpawn = _availableSpawn + _camps;
				};
			};
		};
	};
	
	case 2: {
		/* Enhanced Respawn - Get the camps around the unit */
		_nearestCamps = nearestObjects [_deathLoc, WFCAMP, ('WFBE_RESPAWNRANGE' Call GetNamespace)];
		{
			_get = _x getVariable 'sideID';
			if !(isNil '_get') then {
				if ((_side Call GetSideID) == _get) then {
					if (_respawnCampsRuleMode > 0) then {
						if (_deathLoc distance _x < _respawnMinRange) then {
							_enemySide = if (_side == west) then {[east]} else {[west]};
							if (_respawnCampsRuleMode == 2) then {_enemySide = _enemySide + [resistance]};
							_hostiles = [_x,_enemySide,_respawnMinRange] Call GetHostilesInArea;
							if (_hostiles == 0) then {_availableSpawn = _availableSpawn + [_x]};
						} else {
							_availableSpawn = _availableSpawn + [_x];
						};
					} else {
						_availableSpawn = _availableSpawn + [_x];
					};
				};
			};
		} forEach _nearestCamps;
	};
	
	case 3: {
		/* Defender Only Respawn - Get the camp around the unit only if the town is friendly to the unit. */
		_nearestCamps = nearestObjects [_deathLoc, WFCAMP, ('WFBE_RESPAWNRANGE' Call GetNamespace)];
		{
			_get = _x getVariable 'sideID';
			if !(isNil '_get') then {
				_town = _x getVariable 'town';
				_townSID = _town getVariable 'sideID';
				if ((_side Call GetSideID) == _townSID && _get == _townSID) then {
					if (_respawnCampsRuleMode > 0) then {
						if (_deathLoc distance _x < _respawnMinRange) then {
							_enemySide = if (_side == west) then {[east]} else {[west]};
							if (_respawnCampsRuleMode == 2) then {_enemySide = _enemySide + [resistance]};
							_hostiles = [_x,_enemySide,_respawnMinRange] Call GetHostilesInArea;
							if (_hostiles == 0) then {_availableSpawn = _availableSpawn + [_x]};
						} else {
							_availableSpawn = _availableSpawn + [_x];
						};
					} else {
						_availableSpawn = _availableSpawn + [_x];
					};
				};
			};
		} forEach _nearestCamps;	
	};
	case 4: {
		/* Enhanced Respawn - Get the camps around the unit */
		
		_factoryLeft = (_sideText) Call GetSideStructures;
		sideJoined = playerSide;
		sideJoinedText = str sideJoined;
		_hq = (sideJoinedText) Call GetSideHQ;
if (!alive _hq && count _factoryLeft == 0) then {
	_nearestCamps = nearestObjects [_deathLoc, WFDepot, 150000];
} else {
		_nearestCamps = nearestObjects [_deathLoc, WFDepot, ('WFBE_RESPAWNRANGE' Call GetNamespace)];
		};
		{
			_get = _x getVariable 'sideID';
			if !(isNil '_get') then {
				if ((_side Call GetSideID) == _get) then {
					if (_respawnCampsRuleMode > 0) then {
						//if (_deathLoc distance _x < _respawnMinRange) then {
							_enemySide = if (_side == west) then {[east]} else {[west]};
							if (_respawnCampsRuleMode == 2) then {_enemySide = _enemySide + [resistance]};
							_hostiles = [_x,_enemySide,_respawnMinRange] Call GetHostilesInArea;
							if (_hostiles == 0) then {_availableSpawn = _availableSpawn + [_x]};
						/*} else {
							_availableSpawn = _availableSpawn + [_x];
						};*/
					} else {
						_availableSpawn = _availableSpawn + [_x];
					};
				};
			};
		} forEach _nearestCamps;
	};
};

/* Return the available camps */
_availableSpawn