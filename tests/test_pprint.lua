local pprint = loadfile('../pprint.lua')()

local fmt = string.format

local function test(name, func)
  xpcall(function()
    func()
    print( fmt("[pass] %s", name) )
  end, function(err)
    print( fmt("[fail] %s : %s", name, err) )
  end)
end


------- test case -----------------------------

local a_list = {
    '1', '2', '3\n4'
}

local test_struct = {
    'a',
    100, nil,
    1234567,
    list = a_list,
    ['name'] = 'Tom',
    age = 18,
    hobbys = {
        'game',
        ['ball'] = {
            'football',
            'basketball'
        }
    },
    say_hello = function ()
       print('hello')
    end,
}

function test_struct.jump(one, two, three)
    -- content
end

test('PrettyPrinter.pprint', function ()
    local printer = pprint.PrettyPrinter({
        depth=3,
        scientific_notation=true
    })

    printer:pprint(test_struct)
end)

test('pprint.isrecursive', function ()
    assert(pprint.isrecursive('string') == true)
    assert(pprint.isrecursive(123) == true)
    assert(pprint.isrecursive(false) == true)
    assert(pprint.isrecursive({'a', 'b'}) == false)
end)

--pprint.pprint(test_struct)

