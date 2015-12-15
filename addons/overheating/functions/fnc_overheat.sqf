/*
 * Author: Commy2 and esteldunedain
 * Handle weapon fire, heat up the weapon
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

params ["_unit", "_weapon", "", "", "_ammo", "", "_projectile"];
TRACE_1("params", _this);

// Get physical parameters
private _bulletMass = getNumber (configFile >> "CfgAmmo" >> _ammo >> "ACE_BulletMass");
if (_bulletMass == 0) then {
    // If the bullet mass is not configured, estimate it
    _bulletMass = 3.4334 + 0.5171 * (getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit") + getNumber (configFile >> "CfgAmmo" >> _ammo >> "caliber"));
};
private _energyIncrement = 0.75 * 0.0005 * _bulletMass * (vectorMagnitudeSqr velocity _projectile);

[_unit, _weapon, _energyIncrement] call FUNC(updateTemperature)
