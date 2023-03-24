NIXADDR = 127.0.0.1
NIXPORT = 10000
NIXUSER = vptr


# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

vm/new:
	qemu-img create -f qcow2 nixos-test.img 20G

vm/start0:
	qemu-system-x86_64 -enable-kvm -nic user,ipv6=off,model=e1000,hostfwd=tcp::$(NIXPORT)-:22 -boot once=d -cdrom iso/nixos-minimal-22.11.iso -m 8G -cpu host -smp 8 -hda nixos-test.img

vm/start:
	qemu-system-x86_64 -boot c -vga virtio -netdev user,id=hostnet0,hostfwd=tcp::$(NIXPORT)-:22 -device virtio-net-pci,romfile=,netdev=hostnet0 -device VGA,vgamem_mb=128 -enable-kvm -bios /usr/share/ovmf/OVMF.fd -m 8G -cpu host -smp 8 -hda nixos-test.img
	#qemu-system-x86_64 -vga virtio -netdev user,id=hostnet0 -device virtio-net-pci,romfile=,netdev=hostnet0 -device VGA,vgamem_mb=128 -enable-kvm -bios /usr/share/ovmf/OVMF.fd -nic user,ipv6=off,model=e1000,hostfwd=tcp::$(NIXPORT)-:22 -m 8G -cpu host -smp 8 -hda nixos-test.img
	#qemu-system-x86_64 -vga virtio -netdev user,id=hostnet0 -device virtio-net-pci,romfile=,netdev=hostnet0 -device VGA,vgamem_mb=128 -enable-kvm -bios /usr/share/ovmf/OVMF.fd -nic user,ipv6=off,model=e1000,hostfwd=tcp::$(NIXPORT)-:22 -boot once=d -cdrom nixos-minimal-22.11.iso -m 8G -cpu host -smp 8 -hda nixos-test.img
	

vm/bootstrap0:
	# copy all configs onto VM so we can initialize entire system in one
	# shot
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='.git/' \
		--exclude='iso/' \
		--exclude='*.iso' \
		--exclude='*.img' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ root@$(NIXADDR):/nix-config

    # setup system and install nixos using flake
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MiB -8GiB; \
		parted /dev/sda -- mkpart primary linux-swap -8GiB 100\%; \
		parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB; \
		parted /dev/sda -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/sda1 ; \
		mkswap -L swap /dev/sda2 ; \
		mkfs.fat -F 32 -n boot /dev/sda3 ; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-install --no-root-passwd --flake /nix-config\#nixos; \
		poweroff; \
#		nixos-generate-config --root /mnt; \
#		sed --in-place '/system\.stateVersion = .*/a \
#			nix.package = pkgs.nixUnstable;\n \
#			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
#  			services.openssh.enable = true;\n \
#			services.openssh.passwordAuthentication = true;\n \
#			services.openssh.permitRootLogin = \"yes\";\n \
#			users.users.root.initialPassword = \"root\";\n \
#			boot.loader.grub.device = \"nodev\";\n \
#			boot.loader.grub.efiSupport = true;\n \
#			boot.loader.grub.efiInstallAsRemovable = true;\n \
#		' /mnt/etc/nixos/configuration.nix; \
#		nixos-install --no-root-passwd; \
#		nixos-install --no-root-passwd --flake /nix-config#nixos; \
#		poweroff ; \
	"

vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--exclude='*.iso' \
		--exclude='*.img' \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):./nixos-config
