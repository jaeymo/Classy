--!strict
local CollectionService = game:GetService("CollectionService")

local Packages = script.Parent

local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)

local PREFIX = "WRAPPER"

local Classy = {}
Classy.__index = Classy

export type Janitor = Janitor.Janitor

export type ClassyConfig<U> = {
    Predicate: ((Instance) -> boolean)?,
    ClassNames: { string }?,
    Ancestors: {U}?,
}

export type Class<T> = {
    __index: any,

    new: (Instance: Instance, Janitor: Janitor, Metadata: {
        GUID: string?,
    }) -> T,

    [any]: any,
}

export type Classy<T> = typeof(setmetatable({} :: {
    Tag: string,
    Class: T,

    Predicate: ((Instance) -> boolean)?,
    Ancestors: { Instance },
    ClassNames: { string },

    Tracked: { [Instance]: any },
    Janitor: Janitor,

    InstanceAdded: Signal.Signal<Instance, T>,
    InstanceRevoked: Signal.Signal<Instance, T>,
}, Classy))

local function hasClassValidClassName(Instance: Instance, ClassNames: { string } ): boolean
    if next(ClassNames) then
        local Valid = false
        for _, ClassName in ClassNames do
            if Instance:IsA(ClassName) then
                Valid = true
                break
            end
        end

        return Valid
    else
        return false
    end
end

local function hasValidAncestors(Instance: Instance, Ancestors: { Instance } ): boolean
    if next(Ancestors) then
		local Valid = false
		for _, Ancestor in Ancestors do
			if Instance:IsDescendantOf(Ancestor) then
				Valid = true
				break
			end
		end

        return Valid
    else
        return false
    end
end

function Classy.new<T, U>(Tag: string, Class: T, ClassyConfig: ClassyConfig<U>?): Classy<T>
    local Config: ClassyConfig<U> = (ClassyConfig or {})

    local self = setmetatable({
        Class = Class,
        Tag = Tag,

        Ancestors = table.freeze(Config.Ancestors or {}),
        ClassNames = table.freeze(Config.ClassNames or {}),
        Predicate = Config.Predicate,

        Janitor = Janitor.new(),
        Tracked = {},

        InstanceAdded = Signal.new(),
        InstanceRevoked = Signal.new(),
    }, Classy)::Classy<T>

    self:_watch()

    return self
end

function Classy.CanBeApplied<T>(self: Classy<T>, Instance: Instance): boolean
    if typeof(Instance) ~= "Instance" then
        warn(`[{PREFIX}] Expected typeof "Instance", got: {typeof(Instance)}`)
        return false
    end

    if not hasClassValidClassName(Instance, self.ClassNames) then
        return false
    end

    if not hasValidAncestors(Instance, self.Ancestors) then
        return false
    end

    if self.Predicate and typeof(self.Predicate) == "function" and not self.Predicate(Instance) then
        return false
    end

    return true
end

function Classy.GetApplied<T>(self: Classy<T>, Instance: Instance)
    return self.Tracked[Instance]
end

function Classy.Apply<T>(self: Classy<T>, Instance: Instance)
    Instance:AddTag(self.Tag)

    local JanitorObject = self.Janitor:Add(Janitor.new())
    JanitorObject:Add(function()
        print("Cleaned up")
    end)

    task.delay(3, function()
        print('clean')
        self.Janitor:Cleanup()
    end)
    
    self.Tracked[Instance] = {}
end

function Classy.Revoke<T>(self: Classy<T>, Instance: Instance)
    
end

function Classy.Destroy<T>(self: Classy<T>)
    self.Janitor:Destroy();
    
    (self.InstanceAdded::any):DisconnectAll();
    (self.InstanceRevoked::any):DisconnectAll();

    table.clear(self::any)
    setmetatable(self::any, nil)
end

function Classy._watch<T>(self: Classy<T>)
    self.Janitor:Add(CollectionService:GetInstanceAddedSignal(self.Tag):Connect(function(Instance: Instance)  
        self:Apply(Instance)
    end))

    self.Janitor:Add(CollectionService:GetInstanceRemovedSignal(self.Tag):Connect(function(Instance: Instance)
        self:Revoke(Instance)
    end))
end

return Classy