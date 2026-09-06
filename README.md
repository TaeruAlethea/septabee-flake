```nix

# Realtime Thread Priority 
imports = [ inputs.septabee.nixosModules.x86_64-linux.default ];

# Actually install the package
environment.systemPackages = [ inputs.septabee.packages.x86_64-linux.default ];

# Optionally say no to wayland
environment.systemPackages = [ inputs.septabee.packages.x86_64-linux.xNoWayland ];


```
