--!strict

-- Forty family-friendly robbery targets distributed through the Mega City.
-- WorldService owns their presentation; RobberyService owns every outcome.
export type LocationVariant = "Storefront" | "Kiosk" | "Arcade" | "Industrial" | "Vault"

export type LocationDefinition = {
	Id: string,
	DisplayName: string,
	ActionText: string,
	TargetName: string,
	Variant: LocationVariant,
	Tier: number,
	Cost: number,
	Reward: number,
	Duration: number,
	Cooldown: number,
	CrimeId: string,
	Color: Color3,
	AccentColor: Color3,
}

local palettes = {
	{ Color3.fromRGB(75, 145, 166), Color3.fromRGB(104, 239, 225) },
	{ Color3.fromRGB(174, 92, 111), Color3.fromRGB(255, 190, 219) },
	{ Color3.fromRGB(106, 84, 156), Color3.fromRGB(246, 210, 78) },
	{ Color3.fromRGB(79, 143, 93), Color3.fromRGB(245, 221, 105) },
	{ Color3.fromRGB(173, 119, 68), Color3.fromRGB(255, 185, 88) },
	{ Color3.fromRGB(72, 92, 129), Color3.fromRGB(111, 185, 255) },
	{ Color3.fromRGB(151, 80, 71), Color3.fromRGB(255, 224, 166) },
	{ Color3.fromRGB(73, 125, 116), Color3.fromRGB(250, 137, 174) },
}

local locations: { LocationDefinition } = {}

local function addLocation(
	id: string,
	displayName: string,
	actionText: string,
	targetName: string,
	variant: LocationVariant,
	tier: number
)
	local index = #locations + 1
	local palette = palettes[((index - 1) % #palettes) + 1]
	local baseCost = if tier == 1 then 50 elseif tier == 2 then 200 else 600
	local baseDuration = if tier == 1 then 5 elseif tier == 2 then 8 else 12
	local baseCooldown = if tier == 1 then 30 elseif tier == 2 then 45 else 70

	local cost = baseCost + ((index - 1) % 5) * (if tier == 1 then 25 elseif tier == 2 then 50 else 100)
	table.insert(locations, {
		Id = id,
		DisplayName = displayName,
		ActionText = actionText,
		TargetName = targetName,
		Variant = variant,
		Tier = tier,
		Cost = cost,
		Reward = cost * 2,
		Duration = baseDuration + ((index - 1) % 3),
		Cooldown = baseCooldown + ((index - 1) % 4) * 5,
		CrimeId = if tier == 1 then "MinorRobbery" elseif tier == 2 then "StoreRobbery" else "MajorRobbery",
		Color = palette[1],
		AccentColor = palette[2],
	})
end

-- Quick neighborhood targets: short timers, lighter rewards, one-star response.
addLocation("BubbleTeaTips", "BUBBLE TEA", "Grab Tip Jar", "TIP JAR", "Kiosk", 1)
addLocation("ToyBoxTill", "TOY BOX", "Rob Toy Till", "TOY TILL", "Storefront", 1)
addLocation("CityPizzaRegister", "CITY PIZZA", "Rob Pizza Till", "PIZZA TILL", "Storefront", 1)
addLocation("PetShopRegister", "PET SHOP", "Rob Register", "PET SHOP TILL", "Storefront", 1)
addLocation("CornerCafeTips", "CORNER CAFE", "Grab Tip Jar", "CAFE TIPS", "Kiosk", 1)
addLocation("IceCreamTill", "ICE CREAM", "Rob Ice Cream Till", "ICE CREAM TILL", "Kiosk", 1)
addLocation("FlowerShopTill", "FLOWER SHOP", "Rob Flower Till", "FLOWER TILL", "Storefront", 1)
addLocation("BookNookCashbox", "BOOK NOOK", "Open Cashbox", "BOOK CASHBOX", "Storefront", 1)
addLocation("JuiceBarTips", "JUICE BAR", "Grab Tip Jar", "JUICE TIPS", "Kiosk", 1)
addLocation("CandyShopTill", "CANDY SHOP", "Rob Candy Till", "CANDY TILL", "Storefront", 1)
addLocation("ArtSupplyTill", "ART SUPPLY", "Rob Art Till", "ART TILL", "Storefront", 1)
addLocation("DonutShopRegister", "DONUT PLANET", "Rob Donut Till", "DONUT TILL", "Kiosk", 1)
addLocation("SmoothieStandTill", "SMOOTHIE STAND", "Rob Smoothie Till", "SMOOTHIE TILL", "Kiosk", 1)
addLocation("TacoTimeCashbox", "TACO TIME", "Open Cashbox", "TACO CASHBOX", "Kiosk", 1)
addLocation("CoffeeHouseTips", "COFFEE HOUSE", "Grab Tip Jar", "COFFEE TIPS", "Kiosk", 1)

-- Standard city jobs: longer holdouts, stronger two-star police response.
addLocation("PixelPalacePrizes", "PIXEL PALACE", "Crack Prize Safe", "PRIZE SAFE", "Arcade", 2)
addLocation("ComicClubCashbox", "COMIC CLUB", "Open Cashbox", "COMIC CASHBOX", "Storefront", 2)
addLocation("BakeryRegister", "SUNRISE BAKERY", "Rob Bakery Till", "BAKERY TILL", "Storefront", 2)
addLocation("SportsShopLocker", "SPORTS ZONE", "Open Team Locker", "TEAM LOCKER", "Industrial", 2)
addLocation("GameShopVault", "GAME SHOP", "Crack Game Vault", "GAME VAULT", "Arcade", 2)
addLocation("HobbyShopCashbox", "HOBBY SHOP", "Open Cashbox", "HOBBY CASHBOX", "Storefront", 2)
addLocation("RobotLabPrototype", "ROBOT LAB", "Grab Glorp Chip", "GLORP CHIP", "Vault", 2)
addLocation("BikeShopRegister", "BIKE SHOP", "Rob Bike Till", "BIKE TILL", "Industrial", 2)
addLocation("SkateShopLocker", "SKATE SHOP", "Open Gear Locker", "GEAR LOCKER", "Industrial", 2)
addLocation("MetroMarketRegister", "METRO MARKET", "Rob Market Till", "MARKET TILL", "Storefront", 2)
addLocation("FashionBoutiqueTill", "FASHION BOUTIQUE", "Rob Boutique Till", "FASHION TILL", "Storefront", 2)
addLocation("GadgetShopSafe", "GADGET SHOP", "Crack Gadget Safe", "GADGET SAFE", "Vault", 2)
addLocation("TownMarketTill", "TOWN MARKET", "Rob Market Till", "TOWN TILL", "Storefront", 2)
addLocation("MusicShopRegister", "MUSIC SHOP", "Rob Music Till", "MUSIC TILL", "Storefront", 2)
addLocation("CinemaTicketBooth", "STAR CINEMA", "Rob Ticket Booth", "TICKET BOOTH", "Kiosk", 2)

-- High-value landmarks: bigger rewards and immediate three-star dispatch.
addLocation("FamilyFunPrizeVault", "FAMILY FUN", "Crack Prize Vault", "PRIZE VAULT", "Arcade", 3)
addLocation("CarWashPayStation", "GLORP CAR WASH", "Open Pay Station", "PAY STATION", "Industrial", 3)
addLocation("ParkingGarageBooth", "WEST PARKING", "Rob Parking Booth", "PARKING BOOTH", "Kiosk", 3)
addLocation("GasKioskRegister", "ROCKET FUEL", "Rob Fuel Kiosk", "FUEL REGISTER", "Kiosk", 3)
addLocation("LaundromatCoinBox", "SPIN CITY", "Open Coin Box", "COIN BOX", "Industrial", 3)
addLocation("FurnitureStoreSafe", "COMFY CORNER", "Crack Store Safe", "FURNITURE SAFE", "Vault", 3)
addLocation("AquariumGiftShop", "AQUARIUM GIFTS", "Rob Gift Shop", "GIFT SHOP TILL", "Storefront", 3)
addLocation("StarHotelFrontDesk", "STAR HOTEL", "Rob Front Desk", "HOTEL LOCKBOX", "Vault", 3)
addLocation("WarehouseShipment", "WESTSIDE CARGO", "Open Shipment Box", "SHIPMENT BOX", "Industrial", 3)
addLocation("GemGalleryVault", "GEM GALLERY", "Crack Gem Vault", "GEM VAULT", "Vault", 3)

local RobberyLocationConfig = {
	Locations = locations,
}

return table.freeze(RobberyLocationConfig)
