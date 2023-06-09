
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

-- 定义一个基本的类
local Animal = class()
function Animal:new(name)
    self.name = name
end

function Animal:all()
    self:speak()
    self:_eat()
end

function Animal:speak()
    print("I am an animal, my name is: " .. self.name)
end

function Animal:_eat()
    print("I like eat eat eat.")
end


-- 创建一个 Animal 实例并调用方法
local animal = Animal("Buddy")
animal:speak() -- 输出: I am an animal, my name is: Buddy
print('------------------')
animal:all()

