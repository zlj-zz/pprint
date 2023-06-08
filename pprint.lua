
local pprint = {_version = '0.1.0'}

local _insert = table.insert

---Adjust a `table` wether is a list.
---@param t table
---@return boolean
local function is_list(t)
    local count = 0
    for k, _ in pairs(t) do
        -- the key should be a number
        if type(k) ~= "number" then
            return false
        end

        -- the key should be increment
        if k > count + 1 then
            return false
        end
    end

    return count == #t
end

local function class(baseClass)
    local newClass = {}
    newClass.__index = newClass
    newClass.__call = function(cls, ...)
        local instance = setmetatable({}, cls)
        if instance.new then
            instance:new(...)
        end
        return instance
    end
    if baseClass then
        setmetatable(newClass, baseClass)
    else
        setmetatable(newClass, { __call = newClass.__call })
    end
    return newClass
end

local PerttyPrinter = class()

---New a `PerttyPrinter` instance.
---@param ident integer?
---@param width integer?
---@param depth integer?
---@param compact boolean?
---@param sort_tables boolean?
---@param underscore_numbers boolean?
function PerttyPrinter:new(ident, width, depth, compact, sort_tables, underscore_numbers)
    local _indent = ident or 1
    local _width = width or 80

    if _indent < 0 then error('ident must be >= 0') end
    if _width < 0 then error('width must be >= 0') end

    self._ident = _indent
    self._width = width
    self._depth = depth
    self.compact = compact
    self.sort_tables = sort_tables
    self.underscore_numbers = underscore_numbers
end


return pprint
