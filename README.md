# Minecraft Server-Maintainer

This guide assumes you got a bare metal Ubuntu machine to run your server on.

## Prerequisites

- Ubuntu 18.04 LTS
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
8 Hit `ENTER`

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
Distributed under the MIT License. See ` LICENSE ` for more information.

Contact
Viktor Tkachuk - `vicketchup@gmail.com`

Project Link: `https://github.com/VicKetchup/minecraft-server-maintainer`
