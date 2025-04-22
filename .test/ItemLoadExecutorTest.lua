---@class AbstractFramework
local AF = _G.AbstractFramework

local GROUP_1_LABEL = "ItemGroup1"
local GROUP_2_LABEL = "ItemGroup2"
local GROUP_3_LABEL = "ItemGroup3"
local GROUP_4_LABEL = "ItemGroup4"

print("Starting ItemLoadExecutor test...")

if not TEST_EXECUTOR then
    local function ItemHandler(executor, itemMixin, itemID, index, total, groupLabel)
        if itemMixin then
            local link = itemMixin:GetItemLink() or "[]"

            print(string.format("[%s] %d/%d: Loaded item %d - %s",
                groupLabel, index, total, itemID, link))
        else
            print(string.format("[%s] %d/%d: Failed to load item %d",
                groupLabel, index, total, itemID))
        end
    end

    local function OnGroupStart(executor, groupLabel)
        print("====== Started group: " .. groupLabel .. " ======")
    end

    local function OnGroupFinish(executor, groupLabel)
        print("====== Finished group: " .. groupLabel .. " ======")
    end

    local function OnAllFinish(executor)
        print("All groups finished!")
    end

    TEST_EXECUTOR = AF.BuildItemLoadExecutor(ItemHandler, OnGroupStart, OnGroupFinish, OnAllFinish)
end

local group1 = {}
local group2 = {}
local group3 = {}
local group4 = {}

for i = 100000, 100009 do
    table.insert(group1, i)
    table.insert(group2, i + 100000)
    table.insert(group3, i + 200000)
    table.insert(group4, i + 300000)
end

TEST_EXECUTOR:Submit(group1, GROUP_1_LABEL)
TEST_EXECUTOR:Submit(group2, GROUP_2_LABEL)

C_Timer.After(2, function()
    TEST_EXECUTOR:Submit(group3, GROUP_3_LABEL)
    TEST_EXECUTOR:Submit(group4, GROUP_4_LABEL)
end)