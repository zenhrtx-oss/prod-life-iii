# Compose a build script that embeds lib/BuildLib.lua as a long string: python3 compose.py NN_name.lua > out.lua
import sys, pathlib
here = pathlib.Path(__file__).parent
lib = (here / "lib" / "BuildLib.lua").read_text()
src = (here / sys.argv[1]).read_text()
print(src.replace("--@@BUILDLIB@@", "local BUILDLIB_SRC = [=====[\n" + lib + "\n]=====]"))
