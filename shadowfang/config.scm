(use-modules (gnu)
             (gnu packages xorg)
             (gnu packages linux)
             (gnu packages android)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules
  linux
  cups
  desktop
  networking
  ssh
  xorg)

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Los_Angeles")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "shadowfang")
  (users (cons* (user-account
                  (name "archit")
                  (comment "Archit Gupta")
                  (group "users")
                  (home-directory "/home/archit")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (kernel linux)
  (kernel-loadable-modules (list v4l2loopback-linux-module))
  (initrd (lambda (file-systems . rest)
          (apply microcode-initrd file-systems
                 #:microcode-packages (list intel-microcode)
                 rest)))
  (firmware (list ibt-hw-firmware iwlwifi-firmware))
  (packages
    (append
      (list (specification->package "nss-certs"))
      %base-packages))
  (services
    (append
      (list (service gnome-desktop-service-type)
            (service cups-service-type)
            (set-xorg-configuration
              (xorg-configuration
               (keyboard-layout keyboard-layout)
               (modules (list xf86-input-libinput))
               (drivers '("modesetting"))))
            (service kernel-module-loader-service-type
                     '("v4l2loopback")))
      (modify-services %desktop-services
        (guix-service-type config => (guix-configuration
          (inherit config)
          (substitute-urls
            (append %default-substitute-urls
              (list "https://substitutes.nonguix.org")))
          (authorized-keys
            (append %default-authorized-guix-keys
                    (list (plain-file "non-guix.pub"
                                      "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))")))))))))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid "511656cb-715e-41ee-8a2a-1095c81bb40d"))
            (target "cryptroot")
            (type luks-device-mapping))))
  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
             (device (uuid "67FA-993F" 'fat32))
             (type "vfat"))
           (file-system
             (mount-point "/")
             (device "/dev/mapper/cryptroot")
             (type "ext4")
             (dependencies mapped-devices))
           %base-file-systems)))
