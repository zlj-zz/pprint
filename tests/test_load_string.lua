local str = [[ return {
  [1] = "a",
  [2] = 100,
  [4] = 1234567,
  ['hobbys'] = {
               [1] = "game",
               ['ball'] = {
                          "football",
                          "basketball",
                        },
             },
  ['list'] = {
             "1",
             "2",
             "3"
             .."4",
           },
  ['age'] = 18,
  ['say_hello'] = function (one) end,
  ['name'] = "Tom",
}
]]

local generate_fn, err = load(str)
if err == nil then
    local tb = generate_fn()

    assert(tb.name == 'Tom')
    assert(tb[1] == 'a')
    assert(tb[2] == 100)
end



