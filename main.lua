PacifistMod = RegisterMod("Pacifist", 1)
local mod = PacifistMod

local vectorZero = Vector.Zero or Vector(0,0)

CollectibleType.COLLECTIBLE_PACIFIST = Isaac.GetItemIdByName("Pacifist")

local Pacdesc = "Gives pickup rewards on the next floor based on how many rooms you haven't cleared on the current floor"
local PacdescRu = "Дает награду предметами на следующем этаже в зависимости от того, сколько комнат вы не зачистили на текущем"
local PacdescSpa = "Genera recolectables en el siguiente piso en función a cuantas habitaciones no limpiaste en el piso actual"

if MiniMapiItemsAPI then
    local frame = 0
    local pacifistSprite = Sprite()
    pacifistSprite:Load("gfx/ui/minimapitems/pacifist_icon.anm2", true)
    MiniMapiItemsAPI:AddCollectible(CollectibleType.COLLECTIBLE_PACIFIST, pacifistSprite, "CustomIconPacifist", frame)
end

if EID then
    EID:addCollectible(CollectibleType.COLLECTIBLE_PACIFIST, Pacdesc, "Pacifist")
	EID:addCollectible(CollectibleType.COLLECTIBLE_PACIFIST, PacdescRu, "Пацифист", "ru")
	EID:addCollectible(CollectibleType.COLLECTIBLE_PACIFIST, PacdescSpa, "Pacifista", "spa")
end

if Encyclopedia then
	Encyclopedia.AddItem({
	  ID = CollectibleType.COLLECTIBLE_PACIFIST,
	  WikiDesc = Encyclopedia.EIDtoWiki(Pacdesc),
	  Pools = {
		Encyclopedia.ItemPools.POOL_ANGEL,
		Encyclopedia.ItemPools.POOL_GREED_ANGEL,
	  },
	})
end

PacifistMod.RoomsCleared = 0 --these dont need to be player data since its global to all players
PacifistMod.PickupsToSpawn = 0
PacifistMod.CurrentLevelRooms = -1

function mod:OnGetPacifist(player)
	local seeds = Game():GetSeeds()

	if player:HasCollectible(CollectibleType.COLLECTIBLE_PACIFIST) then
		if not seeds:HasSeedEffect(SeedEffect.SEED_PACIFIST) then
			--seeds:AddSeedEffect(SeedEffect.SEED_PACIFIST) 
			--this has to be manually recreated.
		end
	end
end
--mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OnGetPacifist)

function mod:CheckRooms()
	PacifistMod.CurrentLevelRooms = PacifistMod.CurrentLevelRooms < 0 and Game():GetLevel():GetRoomCount() or PacifistMod.CurrentLevelRooms
	if mod:WasRoomJustCleared() then
		PacifistMod.RoomsCleared = PacifistMod.RoomsCleared + 1
		PacifistMod.PickupsToSpawn = PacifistMod.CurrentLevelRooms - PacifistMod.RoomsCleared
	end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.CheckRooms)

function mod:PickupsDrop() --spawn pickups every level after pickup
	for playerNum = 0, Game():GetNumPlayers() - 1 do
		local player = Game():GetPlayer(playerNum)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_PACIFIST) then
			for i = 1, PacifistMod.PickupsToSpawn do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_NULL, 0, Isaac.GetFreeNearPosition(player.Position, 1), vectorZero, player)
			end
		end
	end

	PacifistMod.CurrentLevelRooms = Game():GetLevel():GetRoomCount()
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.PickupsDrop)

function mod:onStart(isContinued)
	PacifistMod.CurrentLevelRooms = Game():GetLevel():GetRoomCount()
	if isContinued and mod:HasData() then
		PacifistMod.RoomsCleared = mod:LoadData()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onStart)

function mod:onExit(isSaving)
	PacifistMod.CurrentLevelRooms = Game():GetLevel():GetRoomCount()
	if isSaving then
		mod:SaveData(PacifistMod.RoomsCleared)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onExit)
-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

--returns true if the room was just cleared
local roomWasCleared = true
local roomWasJustCleared = false
function mod:WasRoomJustCleared()
	return roomWasJustCleared
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()

	local game = Game()
	local room = game:GetRoom()

	local roomIsCleared = room:GetAliveEnemiesCount() == 0 and not room:IsClear()

	roomWasJustCleared = false
	if roomIsCleared and not roomWasCleared then
		roomWasJustCleared = true
	end
	
	roomWasCleared = roomIsCleared
end)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	roomWasJustCleared = false
	roomWasCleared = true
	PacifistMod.RoomsCleared = 0
	PacifistMod.PickupsToSpawn = 0
end)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	roomWasJustCleared = false
	roomWasCleared = true
	local room = Game():GetRoom()
	if room:IsClear() and room:IsFirstVisit() then
		PacifistMod.RoomsCleared = PacifistMod.RoomsCleared + 1
		PacifistMod.PickupsToSpawn = PacifistMod.CurrentLevelRooms - PacifistMod.RoomsCleared
	end
end)