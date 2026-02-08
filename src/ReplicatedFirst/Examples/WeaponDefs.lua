local WeaponDefs = {}

WeaponDefs.Weapons = {
	Pistol = {
		name = "Pistol",
		damage = 20,
		fireDelay = 0.3,
		maxAmmo = 12,
		reloadTime = 1.5,
		range = 500,
		price = 0,
		weaponType = "hitscan",
		description = "Reliable sidearm. Everyone starts with one.",
		modelName = "Pistol",
	},
	Shotgun = {
		name = "Shotgun",
		damage = 8, -- per pellet
		pellets = 8,
		spread = 0.08,
		fireDelay = 0.8,
		maxAmmo = 6,
		reloadTime = 2.0,
		range = 100,
		price = 200,
		weaponType = "shotgun",
		description = "Devastating up close, useless at range.",
		modelName = "Shotgun",
	},
	AssaultRifle = {
		name = "AssaultRifle",
		damage = 12,
		fireDelay = 0.1,
		maxAmmo = 30,
		reloadTime = 2.0,
		range = 600,
		price = 500,
		weaponType = "hitscan",
		description = "Rapid-fire workhorse.",
		modelName = "AssaultRifle",
	},
	Sniper = {
		name = "Sniper",
		damage = 70,
		fireDelay = 1.2,
		maxAmmo = 5,
		reloadTime = 2.5,
		range = 800,
		bulletSpeed = 800,
		bulletDrop = -0.1,
		bulletMaxDistance = 800,
		price = 800,
		weaponType = "projectile",
		description = "Slow but lethal at distance.",
		modelName = "Sniper",
	},
	RocketLauncher = {
		name = "RocketLauncher",
		damage = 50,
		fireDelay = 1.5,
		maxAmmo = 3,
		reloadTime = 3.0,
		range = 400,
		rocketSpeed = 80,
		explosionRadius = 15,
		explosionForce = 60,
		price = 1200,
		weaponType = "rocket",
		description = "Area damage with knockback.",
		modelName = "RocketLauncher",
	},
}

-- Ordered list for shop display
WeaponDefs.Order = { "Pistol", "Shotgun", "AssaultRifle", "Sniper", "RocketLauncher" }

function WeaponDefs.Get(name)
	return WeaponDefs.Weapons[name]
end

function WeaponDefs.GetCatalog()
	local catalog = {}
	for _, weaponName in ipairs(WeaponDefs.Order) do
		table.insert(catalog, WeaponDefs.Weapons[weaponName])
	end
	return catalog
end

return WeaponDefs
