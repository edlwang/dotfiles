# Windows-specific setup, sourced by init.sh when SYSTEM_OS=Windows.

# Make `ln -s` create real symlinks instead of silently copying. nativestrict
# fails loudly rather than degrading to a copy when symlinks can't be created --
# that needs Developer Mode on or an elevated shell. That's all Windows needs:
# init.sh is config-only, so there's nothing to install here (see README).
export MSYS=winsymlinks:nativestrict
