# Package

version       = "0.1.0"
author        = "Ico Doornekamp"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["nim_arduino"]
installExt    = @["nim"]



# Dependencies
requires "nim >= 1.1.1", "npeg"
