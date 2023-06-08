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


--test('PerttyPrinter.pprint', function ()
    --local PerttyPrinter = pprint.PerttyPrinter
    --assert(PerttyPrinter, table)

    --local printer = PerttyPrinter()
    --print(type(printer))
    --printer.pprint(test_struct)
--end)

function test()
    local test_struct = {
        '1', '2', '3'
    }

    local printer = pprint.PrettyPrinter()
    printer:pprint(test_struct)
end
test()
