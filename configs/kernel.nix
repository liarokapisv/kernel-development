{ lib
, enableRust
, enableBPF
, enableGdb
, useRustForLinux
, fetchFromGitHub
, fetchurl
,
}:
let
  version = "6.13.0-rc1";
  localVersion = "-development";
in
{
  kernelArgs = {
    inherit enableRust enableGdb;

    inherit version;
    src =
      if useRustForLinux
      then
        fetchFromGitHub
          {
            owner = "Rust-for-Linux";
            repo = "linux";
            rev = "40384c840ea1944d7c5a392e8975ed088ecf0b37";
            hash = "sha256-hRpa524OMPX8MJxX6QliFNyV9XcfDrvBvuAnFXmSbkw=";
          }
      else
        fetchurl {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/snapshot/linux-next-next-20241203.tar.gz";
          sha256 = "sha256-s+AJXQwOMDsPtxo2yBgJIq3NYHTApmJmMm6TD+D9wGw=";
        };

    inherit localVersion;
    modDirVersion = version + lib.optionalString (!useRustForLinux) "-next-20241203" + localVersion;
  };

  kernelConfig = {
    inherit enableRust;

    # See https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/kernel_config.nix
    structuredExtraConfig = with lib.kernel;
      {
        "64BIT" = yes;
        BINFMT_ELF = yes;
        BINFMT_SCRIPT = yes;
        BLK_DEV_INITRD = yes;
        BUG_ON_DATA_CORRUPTION = yes;
        DEBUG_ATOMIC_SLEEP = yes;
        DEBUG_BOOT_PARAMS = yes;
        DEBUG_BUGVERBOSE = yes;
        DEBUG_FS = yes;
        DEBUG_INFO = yes;
        DEBUG_KERNEL = yes;
        DEBUG_MEMORY_INIT = yes;
        DEBUG_MISC = yes;
        DEBUG_PREEMPT = yes;
        DEBUG_SHIRQ = yes;
        DEBUG_STACK_USAGE = yes;
        DEVTMPFS = yes;
        DEVTMPFS_MOUNT = yes;
        EARLY_PRINTK = yes;
        FTRACE = yes;
        IKCONFIG = yes;
        IKCONFIG_PROC = yes;
        IKHEADERS = yes;
        IRQSOFF_TRACER = yes;
        KASAN = yes;
        KGDB = yes;
        KSSAN = yes;
        LOCALVERSION = freeform localVersion;
        LOCK_STAT = yes;
        MAGIC_SYSRQ = yes;
        MODULES = yes;
        MODULE_UNLOAD = yes;
        PRINTK = yes;
        PRINTK_TIME = yes;
        PROC_FS = yes;
        PROVE_LOCKING = yes;
        SCHED_STACK_END_CHECK = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_CONSOLE = yes;
        SLUB_DEBUG = yes;
        STACKTRACE = yes;
        SYSFS = yes;
        TTY = yes;
        UBSAN = yes;
        UNWINDER_FRAME_POINTER = yes;

        # FW_LOADER = yes;
      }
      // lib.optionalAttrs enableBPF {
        BPF_SYSCALL = yes;
        # Enable kprobes and kallsyms: https://www.kernel.org/doc/html/latest/trace/kprobes.html#configuring-kprobes
        # Debug FS is be enabled (done above) to show registered kprobes in /sys/kernel/debug: https://www.kernel.org/doc/html/latest/trace/kprobes.html#the-kprobes-debugfs-interface
        KPROBES = yes;
        KALLSYMS_ALL = yes;
      }
      // lib.optionalAttrs enableRust {
        GCC_PLUGINS = no;
        RUST = yes;
        RUST_OVERFLOW_CHECKS = yes;
        RUST_DEBUG_ASSERTIONS = yes;
        RUST_BUILD_ASSERT_ALLOW = no;
      }
      // lib.optionalAttrs enableGdb {
        DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT = yes;
        GDB_SCRIPTS = yes;
      };

    # Flags that get passed to generate-config.pl
    generateConfigFlags = {
      # Ignores any config errors (eg unused config options)
      ignoreConfigErrors = false;
      # Build every available module
      autoModules = false;
      preferBuiltin = false;
    };
  };
}
