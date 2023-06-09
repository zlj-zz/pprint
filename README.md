A lua library completes data beautification output.

# Usage

The file should dropped into a project or a lua lib, then require by it:

```lua
pprint = require('pprint')
```

## provides of the library

`pprint.pprint()` :
Print the formatted representation of object to stream with a trailing newline.

`pprint.pformat()`
Return the formatted representation of object as a string.

## example

```lua
local pprint = require('pprint')

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
    say_hello = function (one)
       print('hello')
    end,
}

pprint.pprint(test_struct)


--[[ Output:
{
  [1] = "a",
  [2] = 100,
  [4] = 1234567,
  [hobbys] = {
               [1] = "game",
               [ball] = {
                          "football",
                          "basketball",
                        },
             },
  [list] = {
             "1",
             "2",
             "3"
             .."4",
           },
  [age] = 18,
  [say_hello] = function (one) end,
  [name] = "Tom",
}
]]
```
