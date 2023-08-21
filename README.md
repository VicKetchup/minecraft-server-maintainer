# minecraft-server-maintainer
[![v: Beta V2.3.1](https://img.shields.io/badge/v-Beta%20V2.3.1-darkred.svg)](https://github.com/VicKetchup/minecraft-server-maintainer)
[![OS: Ubuntu 20.04 LTS \(Focal Fossa\)](https://img.shields.io/badge/OS-Ubuntu%2022.04%20LTS%20\(Jammy%20Jellyfish\)-orange.svg)](https://ubuntu.com/about/release-cycle#ubuntu)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
#
![easyMaintainer](art/easyMaintainer.png?raw=true)

This guide assumes you got a bare metal Ubuntu machine to run your server on.

## Prerequisites

- 22.04 LTS (Jammy Jellyfish)
  - `https://ubuntu.com/about/release-cycle#ubuntu` 
- Puttygen
  - `https://puttygen.com/download.php?val=49`
- Pageant
  - `https://puttygen.com/download.php?val=43`
- Putty
  - `https://puttygen.com/download.php?val=13`

## Installation

1. Clone the repo
  - `git clone https://github.com/VicKetchup/minecraft-server-maintainer.git`
2. Generate RSA Hash256 key (default) using putty-gen and save both public and private keys in a secure location.
3. Run pageant (open from system tray) and add the saved private key to it.
4. Add public key to authorized_keys in .ssh.
5. Open putty, put hostname: `<ip>`, port: 22 and click Open 🙂.
6. Login as `<your-user>`.
7. Type
  - `./easyMaintainer.sh`
8. Hit `ENTER`

If you find any issues, please submit them to GitHub 🙂

### Usage

To setup your username, follow instructions in provided maintainer-usernames.txt file.

### Contributing

Contributions are always welcome!
1. Fork the project
2. Create your Feature Branch (git checkout -b feature/AmazingFeature)
3. Commit your Changes (git commit -m 'Add some AmazingFeature')
4. Push to the Branch (git push origin feature/AmazingFeature)
5. Open a Pull Request
License
Distributed under the MIT License. See [ LICENSE ](#license) for more information.

<p align="center">
  <img src="art/pc_Co_logo.png?raw=true" height=200px><img src="art/pc_logo.png?raw=tru" height=200px>
</p>

## Contact

Viktor Tkachuk - `vicketchup@gmail.com`

Project Link: `https://github.com/VicKetchup/minecraft-server-maintainer`

## License
minecraft-server-maintaner - Level up your Minecraft Server Maintanance and Control!
Copyright (C) 2023  Viktor Tkachuk, aka. VicKetchup, from Ketchup&Co.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

[![v: Beta V2.3.1](https://img.shields.io/badge/v-Beta%20V2.3.1-darkred.svg)](https://github.com/VicKetchup/minecraft-server-maintainer)
[![OS: Ubuntu 20.04 LTS \(Focal Fossa\)](https://img.shields.io/badge/OS-Ubuntu%2022.04%20LTS%20\(Jammy%20Jellyfish\)-orange.svg)](https://ubuntu.com/about/release-cycle#ubuntu)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
