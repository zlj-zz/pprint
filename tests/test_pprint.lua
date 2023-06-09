local pprint = loadfile('../pprint.lua')()

local fmt = string.format

local function test(name, func)
    xpcall(function()
        func()
        print(fmt("[pass] %s", name))
    end, function(err)
        print(fmt("[fail] %s : %s", name, err))
    end)
end

------- ready -----------------------------------

local a_list = {'1', '2', '3\n4'}

local say = function(msg)
    print('say: ' .. msg)
end
local person = {
    'This is a person',
    ['name'] = 'Tom',
    age = 18,
    parent = nil,
    hobbys = {
        'game',
        ['ball'] = {'football', 'basketball'}
    },
    actions = {'sit', 'walk', 'run', say},
    2 ^ 26, -- a big number
    list = a_list
}

function person.intro()
    print('My name is Tom.')
end

------- test case -------------------------------

test('PrettyPrinter.pprint', function()
    pprint.PrettyPrinter():pprint(person)
end)

test('PrettyPrinter.pprint:depth', function()
    local printer = pprint.PrettyPrinter({
        depth = 3,
        scientific_notation = true
    })

    printer:pprint(person)
end)

test('PrettyPrinter.pprint:compact', function()
    local printer = pprint.PrettyPrinter({
        compact = true
    })

    printer:pprint(person)
end)

test('PrettyPrinter.pprint:isreadable', function()
    assert(pprint.PrettyPrinter({
        depth = 3,
        scientific_notation = true
    }):isreadable(test) == false)

    assert(pprint.PrettyPrinter():isreadable(1) == true)
    assert(pprint.PrettyPrinter():isreadable('a') == true)
    assert(pprint.PrettyPrinter():isreadable(nil) == true)

    assert(pprint.PrettyPrinter():isreadable({1, 2, 3}) == true)

    function abc(...)
        -- no content
    end
    assert(pprint.PrettyPrinter():isreadable({
        abc = abc
    }) == false)

end)

test('pprint.isrecursive', function()
    assert(pprint.isrecursive('string') == true)
    assert(pprint.isrecursive(123) == true)
    assert(pprint.isrecursive(false) == true)
    assert(pprint.isrecursive({'a', 'b'}) == false)
end)
