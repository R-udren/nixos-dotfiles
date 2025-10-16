{ config, lib, ... }:

{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition - Increased to 2G for safety
            ESP = {
              priority = 1;
              name = "ESP";
              type = "EF00";
              size = "2G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" "fmask=0077" ];
              };
            };

            # LUKS encrypted root partition
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";

                # Password entry during boot
                # Create /tmp/secret.key before running disko with your password
                passwordFile = "/tmp/secret.key";

                settings = {
                  # Allow TRIM/discard for SSD performance
                  allowDiscards = true;

                  # Use LUKS2 with argon2id for better security
                  pbkdfAlgo = "argon2id";

                  # Increase PBKDF iterations for security
                  iterTime = 4000; # milliseconds, increases resistance to brute-force
                };

                # Performance optimizations for NVMe SSD
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];

                # BTRFS filesystem inside encrypted container
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "nixos" ];

                  subvolumes = {
                    # Root filesystem - balanced compression
                    "/" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd:5" "noatime" "nodatacow" ];
                    };

                    # Home directories - high compression (user files, documents)
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd:3" "noatime" ];
                    };

                    # Nix store - maximum compression (highly repetitive, rarely modified)
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd:10" "noatime" ];
                    };

                    # System logs - medium compression (good ratio vs access time)
                    "/var/log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd:7" "noatime" ];
                    };

                    # Temporary files - no compression (volatile, rarely accessed)
                    "/var/tmp" = {
                      mountpoint = "/var/tmp";
                      mountOptions = [ "noatime" "nodatacow" ];
                    };

                    # User cache - minimal compression (frequent access, short-lived)
                    "/var/cache" = {
                      mountpoint = "/var/cache";
                      mountOptions = [ "compress=zstd:1" "noatime" "nodatacow" ];
                    };

                    # Snapshots directory - high compression (backup efficiency)
                    "/.snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd:10" "noatime" ];
                    };

                    # Swap subvolume - sized for hibernation + headroom
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "48G"; # RAM (32GB) + 16GB compression/peak headroom
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Ensure critical partitions are available early in boot
  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;

  # Enable periodic TRIM for SSD health
  services.fstrim.enable = true;

  # Memory and swap optimization for laptop
  boot.kernel.sysctl = {
    # Reduce swap usage - keep RAM available for cache (0=never, 100=aggressive)
    "vm.swappiness" = 10;
    
    # Allow overcommit to prevent OOM kills
    "vm.overcommit_memory" = 1;
  };

  # Optional: Enable zswap for compressed swap (requires kernel rebuild)
  boot.kernelParams = [ "zswap.enabled=1" "zswap.compressor=zstd" "zswap.max_pool_percent=25" ];

  # Optional: Snapshots cleanup (uncomment if using snapper)
  services.snapper = {
    configs = {
      root = {
        subvolume = "/";
        extraConfig = ''
          TIMELINE_CREATE="yes"
          TIMELINE_CLEANUP="yes"
          TIMELINE_LIMIT_HOURLY="24"
          TIMELINE_LIMIT_DAILY="7"
          TIMELINE_LIMIT_WEEKLY="0"
          TIMELINE_LIMIT_MONTHLY="0"
          TIMELINE_LIMIT_YEARLY="0"
        '';
      };
    };
  };
}
