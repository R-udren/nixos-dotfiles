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
}
