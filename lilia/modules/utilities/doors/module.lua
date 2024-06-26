﻿--- Configuration for Doors Module.
-- @configurations Doors

--- This table defines the default settings for the Doors Module.
-- @realm shared
-- @table Configuration
-- @field DoorCost The Cost of a door | **number**
-- @field DoorSellRatio Percentage you can sell a door for | **number**
-- @field DoorLockTime Time it takes to lock a door | **number**
DOOR_OWNER = 3
DOOR_TENANT = 2
DOOR_GUEST = 1
DOOR_NONE = 0
MODULE.name = "Utilities - Doors"
MODULE.author = "76561198312513285"
MODULE.discord = "@liliaplayer"
MODULE.desc = "Adds Doors that can be bought"
ACCESS_LABELS = {
    [DOOR_OWNER] = "owner",
    [DOOR_TENANT] = "tenant",
    [DOOR_GUEST] = "guest",
    [DOOR_NONE] = "none",
}
