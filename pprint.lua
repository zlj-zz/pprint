---
--- pprint.lua
---

local pprint = {
    _version = '0.1.0'
}

local _insert = table.insert

---Adjust a `table` whether is a list.
---@param t table
---@return boolean
local function is_list(t)
    local i = 1
    for k in pairs(t) do
        if t[i] == nil then
            return false
        end

        if k ~= i then
            return false
        end
        i = i + 1
    end

    return true
end

---Split string.
---@param input string
---@param delimiter string
---@return table
local function split_string(input, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)

    for match in string.gmatch(input, pattern) do
        table.insert(result, match)
    end

    return result
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
        setmetatable(newClass, {
            __call = newClass.__call
        })
    end
    return newClass
end

local PrettyPrinter = class()

---New function of `PerttyPrinter` instance.
---@param indent integer?
---@param width integer?
---@param depth integer?
---@param compact boolean?
---@param sort_tables boolean?
---@param underscore_numbers boolean?
function PrettyPrinter:new(indent, width, depth, compact, sort_tables, underscore_numbers)

    local _indent = indent or 2
    local _width = width or 80

    if _indent < 0 then
        error('indent must be >= 0')
    end
    if _width < 0 then
        error('width must be >= 0')
    end

    self._per_level_sp = _indent
    self._width = width
    self._depth = depth
    self._compact = compact
    self._sort_tables = sort_tables
    self._underscore_numbers = underscore_numbers
end

---Pretty print
---@param obj any
function PrettyPrinter:pprint(obj)
    local content = {}
    self:_format(obj, 0, 0, content, 0)
    print(table.concat(content))
end

---comment
---@param obj any
---@param indent integer
---@param allowance integer
---@param content table
---@param level integer
function PrettyPrinter:_format(obj, indent, allowance, content, level)
    local o_typ = self:_match_type(obj)
    --print(o_typ)
    local p_fn = self._dispatch[o_typ]

    if p_fn ~= nil then
        p_fn(self, obj, indent, allowance, content, level + 1)
    else
        _insert(content, tostring(obj))
    end
end

---Check a type of object.
---Would return: nil, boolean, number, string, function, table, list
---@param obj any
---@return string
function PrettyPrinter:_match_type(obj)
    local o_typ = type(obj)
    if o_typ == 'table' then
        if is_list(obj) then
            return '_list'
        end
    end

    return '_' .. o_typ
end

function PrettyPrinter:_p_table(obj, indent, allowance, content, level)
    _insert(content, '{\n')

    indent = indent + self._per_level_sp
    for k, v in pairs(obj) do
        _insert(content, string.rep(' ', indent))

        -- TODO: imporve the display of `k` 
        local repr_key = string.format('[%s] = ', tostring(k))
        _insert(content, repr_key)

        self:_format(v, indent + #repr_key, allowance, content, level + 1)

        _insert(content, ',\n')
    end

    _insert(content, '}')
    if level <= 1 then
        _insert(content, '\n')
    end

end

function PrettyPrinter:_p_list(obj, indent, allowance, content, level)
    _insert(content, '{\n')

    indent = indent + self._per_level_sp
    for _, v in ipairs(obj) do
        _insert(content, string.rep(' ', indent))
        self:_format(v, indent, allowance, content, level + 1)
        _insert(content, ',\n')
    end

    _insert(content, '}')
    if level <= 1 then
        _insert(content, '\n')
    end

end

function PrettyPrinter:_p_string(obj, indent, allowance, content, level)
    local str_list = split_string(obj, '\n')
    _insert(content, string.format('"%s"', str_list[1]))

    for i = 2, #str_list do
        local line = '\n' .. string.rep(' ', indent) .. string.format('.."%s"', str_list[i])
        _insert(content, line)
    end

end

function PrettyPrinter:_p_function(obj, indent, allowance, content, level)
    -- TODO: finish it
end

PrettyPrinter._dispatch = {
    _table = PrettyPrinter._p_table,
    _list = PrettyPrinter._p_list,
    _string = PrettyPrinter._p_string,
    _function = PrettyPrinter._p_function

}

pprint.PrettyPrinter = PrettyPrinter

return pprint
