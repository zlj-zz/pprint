import os
import sys
import subprocess

rockspec_name: str = "pprint-{0}-{1}.rockspec"

rockspec_template: str = """
package = "pprint"
version = "%(version)s-%(reversion)s"
source = {
  url = "git://github.com/zlj-zz/pprint.git",
  tag = "v%(version)s", -- git tag
}
description = {
  summary = "A lua library completes data beautification output.",
  detailed = [[
      Pure lua implementation, no external lib dependencies.
  ]],
  homepage = "https://github.com/zlj-zz/pprint",
  license = "MIT",
  maintainer = "Zachary Zhang<zlj19971222@outlook.com>",
}
dependencies = {
  "lua >= 5.2" -- 依赖列表
}
build = {
  type = "builtin",
  modules = {
    ["pprint"] = "pprint.lua" -- lua mode: *.lua
    -- 将库中的其他模块（Lua 文件）列为其他条目
  }
}
"""


def generate_rocksepc(file: str) -> None:
    print(f"Will generate file: ./{file}")

    with open(file_name, "w") as f:
        f.write(
            rockspec_template
            % {
                "version": _version,
                "reversion": _reversion,
            }
        )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            "Usage:",
            "\n\tpython3 rockspec.py <version> <reversion> [option]",
        )
        exit(0)

    _version = sys.argv[1]
    _reversion = sys.argv[2]
    _option = sys.argv[3]
    print(f"receive version: {_version}, reversion: {_reversion}")

    file_name = rockspec_name.format(_version, _reversion)

    if _option == "--pack":
        if not os.path.exists(file_name):
            generate_rocksepc(file_name)

        subprocess.run(f"luarocks pack ./{file_name}".split(" "))
    else:
        generate_rocksepc(file_name)
