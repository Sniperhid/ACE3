/*
 * Author: Commy2 and CAA-Picard
 * Handle weapon fire
 *
 * Argument:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 3: Muzzle <STRING>
 * 4: Ammo <STRING>
 * 5: Magazine <STRING>
 * 6: Projectile <OBJECT>
 *
 * Return value:
 * None
 *
 * Public: No
 */
#include "script_component.hpp"

BEGIN_COUNTER(firedEH);

params ["_unit", "_weapon", "", "", "_ammo", "", "_projectile"];
TRACE_1("params", _this);

// Exit if the unit isn't a player
if !([_unit] call EFUNC(common,isPlayer)) exitWith {};

// Compute new temperature if the unit is the local player
if (_unit == ACE_player) then {
    _this call FUNC(overheat);
};

// Get current temperature from the unit variable
private _variableName = format [QGVAR(%1), _weapon];
private _scaledTemperature = 0 max (((_unit getVariable [_variableName, [0,0]]) select 0) / 1000) min 1;

TRACE_2("",_variableName,_scaledTemperature);

if (ACE_time > (_unit getVariable [QGVAR(lastDrop), -1000]) + 0.40 && _scaledTemperature > 0.1) then {
    _unit setVariable [QGVAR(lastDrop), ACE_time];

    private _direction = (_unit weaponDirection _weapon) vectorMultiply 0.25;
    private _position = (position _projectile) vectorAdd (_direction vectorMultiply (4*(random 0.30)));

    if (GVAR(enableRefractEffect)) then {
        // Refract SFX, beginning at temp 100º and maxs out at 500º
        _intensity = (_scaledTemperature - 0.10) / 0.40 min 1;
        drop [
        "\A3\data_f\ParticleEffects\Universal\Refract",
        "",
        "Billboard",
        10,
        2,
        _position,
        _direction,
        0,
        1.2,
        1.0,
        0.1,
        [0.10,0.25],
        [[0.6,0.6,0.6,0.3*_intensity],[0.2,0.2,0.2,0.05*_intensity]],
        [0,1],
        0.1,
        0.05,
        "",
        "",
        ""
        ];
    };

    // Smoke SFX, beginning at temp 150º
    private _intensity = (_scaledTemperature - 0.15) / 0.85;
    if (_intensity > 0) then {
        drop [
        ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 12, 1, 16],
        "",
        "Billboard",
        10,
        1.2,
        _position,
        [0,0,0.15],
        100 + random 80,
        1.275,
        1,
        0.025,
        [0.15,0.43],
        [[0.6,0.6,0.6,0.5*_intensity],[0.2,0.2,0.2,0.15*_intensity]],
        [0,1],
        1,
        0.04,
        "",
        "",
        ""
        ];
    };
};


// Dispersion and bullet slow down

private _dispersion = getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_Dispersion");

_dispersion = ([[0, _dispersion, 2*_dispersion, 4*_dispersion], 3 * _scaledTemperature] call EFUNC(common,interpolateFromArray)) max 0;

private _slowdownFactor = getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_SlowdownFactor");

if (_slowdownFactor == 0) then {_slowdownFactor = 1};

_slowdownFactor = ([[_slowdownFactor, _slowdownFactor, _slowdownFactor, 0.9*_slowdownFactor], 3 * _scaledTemperature] call EFUNC(common,interpolateFromArray)) max 0;


// Exit if GVAR(pseudoRandomList) isn't synced yet
if (isNil QGVAR(pseudoRandomList)) exitWith {};

// Get the pseudo random values for dispersion from the remaining ammo count
private _pseudoRandomPair = GVAR(pseudoRandomList) select ((_unit ammo _weapon) mod count GVAR(pseudoRandomList));

[_projectile, (_pseudoRandomPair select 0) * _dispersion, (_pseudoRandomPair select 1) * _dispersion, (_slowdownFactor - 1) * vectorMagnitude (velocity _projectile)] call EFUNC(common,changeProjectileDirection);


// Only compute jamming for the local player
if (_unit != ACE_player) exitWith {};

private _jamChance = 1 / getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_MRBS"); // arma handles division by 0

_jamChance = [[0.5*_jamChance, 1.5*_jamChance, 7.5*_jamChance, 37.5*_jamChance], 3 * _scaledTemperature] call EFUNC(common,interpolateFromArray);

// increase jam chance on dusty grounds if prone
if (stance _unit == "PRONE") then {
    private _surface = toArray (surfaceType getPosASL _unit);
    _surface deleteAt 0;

    _surface = configFile >> "CfgSurfaces" >> toString _surface;
    if (isClass _surface) then {
        _jamChance = _jamChance + (getNumber (_surface >> "dust")) * _jamChance;
    };
};

if (random 1 < _jamChance) then {
    [_unit, _weapon] call FUNC(jamWeapon);
};

END_COUNTER(firedEH);
