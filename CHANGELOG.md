# 0.1 (Bitcoin 0.16.1)

- Moved from an Ubuntu image (~4GB) to Alpine (~90MB).

# 1.0

- Big rewrite; pretty much everything has changed. On Debian now.
- Volume mounts
  - Old: /root/.bitcoin
  - New: /bitcoin/data
- Specify user config file by mounting volume to /bitcoin/bitcoin.conf
