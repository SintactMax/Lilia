﻿--- Structure of Weapon Item Base.
-- @items Weapon

--- This table defines the default structure of the weapon item base.
-- @realm shared
-- @table Configuration
-- @field name Name of the item | **string**
-- @field desc Description of the item | **string**
-- @field model Model path of the item | **string**
-- @field width Width of the item | **number**
-- @field height Height of the item | **number**
-- @field category Category of the item | **string**
-- @field RequiredSkillLevels Required attribute levels for using the item | **table**
-- @field class The class of the weapon | **string**
-- @field weaponCategory The weapon category of the item. This prevents you from equipping 2 of the same weapon category types | **string**
ITEM.name = "Weapon"
ITEM.desc = "A Weapon."
ITEM.category = "Weapons"
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.class = "weapon_pistol"
ITEM.width = 2
ITEM.height = 2
ITEM.isWeapon = true
ITEM.weaponCategory = "sidearm"
ITEM.RequiredSkillLevels = nil
if CLIENT then
    function ITEM:paintOver(item, w, h)
        if item:getData("equip") then
            surface.SetDrawColor(110, 255, 110, 100)
            surface.DrawRect(w - 14, h - 14, 8, 8)
        end
    end
end

ITEM:hook("drop", function(item)
    if item:getData("equip") then
        local client = item.player
        item:setData("equip", nil)
        client.carryWeapons = client.carryWeapons or {}
        local weapon = client.carryWeapons[item.weaponCategory]
        if IsValid(weapon) then
            item:setData("ammo", weapon:Clip1())
            client:StripWeapon(item.class)
            client.carryWeapons[item.weaponCategory] = nil
            client:EmitSound(item.unequipSound or "items/ammo_pickup.wav", 80)
        end
    end
end)

ITEM.functions.EquipUn = {
    name = "Unequip",
    tip = "equipTip",
    icon = "icon16/cross.png",
    onRun = function(item)
        local client = item.player
        client.carryWeapons = client.carryWeapons or {}
        local weapon = client.carryWeapons[item.weaponCategory]
        if not weapon or not IsValid(weapon) then weapon = client:GetWeapon(item.class) end
        if weapon and weapon:IsValid() then
            item:setData("ammo", weapon:Clip1())
            client:StripWeapon(item.class)
        else
            print(Format("[Lilia] Weapon %s does not exist!", item.class))
        end

        client:EmitSound(item.unequipSound or "items/ammo_pickup.wav", 80)
        client.carryWeapons[item.weaponCategory] = nil
        item:setData("equip", nil)
        lia.chat.send(client, "actions", "puts away his weapon", false)
        if item.onUnequipWeapon then item:onUnequipWeapon(client, weapon) end
        return false
    end,
    onCanRun = function(item) return not IsValid(item.entity) and item:getData("equip", false) end
}

ITEM.functions.Equip = {
    name = "Equip",
    tip = "equipTip",
    icon = "icon16/tick.png",
    onRun = function(item)
        local client = item.player
        local items = client:getChar():getInv():getItems()
        client.carryWeapons = client.carryWeapons or {}
        for _, v in pairs(items) do
            if v.id ~= item.id and v.isWeapon and client.carryWeapons[item.weaponCategory] and v:getData("equip") then
                client:notifyLocalized("weaponSlotFilled")
                return false
            end
        end

        if client:HasWeapon(item.class) then client:StripWeapon(item.class) end
        local weapon = client:Give(item.class, false)
        if IsValid(weapon) then
            timer.Simple(0, function() client:SelectWeapon(weapon:GetClass()) end)
            client.carryWeapons[item.weaponCategory] = weapon
            client:EmitSound(item.equipSound or "items/ammo_pickup.wav", 80)
            local ammoCount = client:GetAmmoCount(weapon:GetPrimaryAmmoType())
            if ammoCount == weapon:Clip1() and item:getData("ammo", 0) == 0 then client:RemoveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType()) end
            item:setData("equip", true)
            weapon:SetClip1(item:getData("ammo", 0))
            lia.chat.send(client, "actions", "takes out his weapon", false)
            if item.onEquipWeapon then item:onEquipWeapon(client, weapon) end
        else
            print(Format("[Lilia] Weapon %s does not exist!", item.class))
        end
        return false
    end,
    onCanRun = function(item) return not IsValid(item.entity) and not item:getData("equip", false) end
}

function ITEM:OnCanBeTransfered(_, newInventory)
    if newInventory and self:getData("equip") then return false end
    return true
end

function ITEM:onLoadout()
    if self:getData("equip") then
        local client = self.player
        client.carryWeapons = client.carryWeapons or {}
        local weapon = client:Give(self.class, false)
        if IsValid(weapon) then
            client:RemoveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType())
            client.carryWeapons[self.weaponCategory] = weapon
            weapon:SetClip1(self:getData("ammo", 0))
        else
            print(Format("[Lilia] Weapon %s does not exist!", self.class))
        end
    end
end

function ITEM:onSave()
    local client = self.player
    local weapon = client:GetWeapon(self.class)
    if IsValid(weapon) then self:setData("ammo", weapon:Clip1()) end
end