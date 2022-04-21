PacifistMod = RegisterMod("Pacifist", 1)
local mod = PacifistMod

CollectibleType.COLLECTIBLE_PACIFIST = Isaac.GetItemIdByName("Pacifist")

local Pacdesc = "Gives pickup rewards on the next floor based on how many rooms you haven't cleared on the current floor"
local PacdescRu = "Дает награду предметами на следующем этаже в зависимости от того, сколько комнат вы не зачистили на текущем"
local PacdescSpa = "Genera recolectables en el siguiente piso en función a cuantas habitaciones no limpiaste en el piso actual"

if MiniMapiItemsAPI then
	local pacifistIcon = Sprite()
	pacifistIcon:Load("gfx/ui/minimapitems/pacifist_icon.anm2", true)	
    MiniMapiItemsAPI:AddCollectible(CollectibleType.COLLECTIBLE_PACIFIST, pacifistIcon, "CustomIconPacifist", 0)
end

if EID then
	EID:setModIndicatorName("Pacifist")

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

local PickupsToSpawn = 0

function mod:PacifistEffect(player)
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	if player:HasCollectible(CollectibleType.COLLECTIBLE_PACIFIST) then
		local sprite = player:GetSprite()
		if sprite:IsPlaying("Trapdoor") and PickupsToSpawn == 0 then
			local rooms = level:GetRooms()
			local clearedRooms = 0
			for i = 0, rooms.Size - 1 do
				local room = rooms:Get(i)
				if room.Clear then
					clearedRooms = clearedRooms + 1
				end
			end
			
			PickupsToSpawn = level:GetRoomCount() - clearedRooms
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.PacifistEffect)

function mod:PickupsDrop() --spawn pickups every level after pickup
	for p = 0, Game():GetNumPlayers() - 1 do
		local player = Game():GetPlayer(p)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_PACIFIST) then
			for i = 1, PickupsToSpawn do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_NULL, 2, Game():GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, player)
			end
		end
	end
	
	PickupsToSpawn = 0
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.PickupsDrop)