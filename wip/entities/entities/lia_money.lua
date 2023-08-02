AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Money"
ENT.Category = "Lilia"
ENT.Spawnable = false

if SERVER then
    function ENT:Initialize()
        self:SetModel(hook.Run("GetMoneyModel", self:getAmount()) or lia.config.MoneyModel)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local physObj = self:GetPhysicsObject()

        if IsValid(physObj) then
            physObj:EnableMotion(true)
            physObj:Wake()
        else
            local min, max = Vector(-8, -8, -8), Vector(8, 8, 8)
            self:PhysicsInitBox(min, max)
            self:SetCollisionBounds(min, max)
        end
    end

    function ENT:Use(activator)
        local character = activator:getChar()
        if not character then return end

        if self.client == activator and character:getID() ~= self.charID then
            activator:notifyLocalized("logged")

            return
        end

        if hook.Run("OnPickupMoney", activator, self) ~= false then
            self:Remove()
        end
    end
else
    ENT.DrawEntityInfo = true
    local toScreen = FindMetaTable("Vector").ToScreen
    local colorAlpha = ColorAlpha
    local drawText = lia.util.drawText

    function ENT:onDrawEntityInfo(alpha)
        local position = toScreen(self:LocalToWorld(self:OBBCenter()))
        local x, y = position.x, position.y
        drawText(lia.currency.get(self:getAmount()), x, y, colorAlpha(lia.config.Color), 1, 1, nil, alpha * 0.65)
    end
end

function ENT:setAmount(amount)
    self:setNetVar("amount", amount)
end

function ENT:getAmount()
    return self:getNetVar("amount", 0)
end