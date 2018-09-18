#!/bin/bash
set -euo pipefail


# install:
# curl -L https://raw.githubusercontent.com/do-community/automated-setups/master/Ubuntu-18.04/initial_server_setup.sh -o /tmp/initial_setup.sh
# bash <(curl -s https://raw.githubusercontent.com/BercziSandor/hasznaltAutoWatcher/master/installDigitalCloud/initial_setup.sh)

########################
### SCRIPT VARIABLES ###
########################

# Name of the user to create and grant sudo privileges
USERNAME=sanyi

# Whether to copy over the root user's `authorized_keys` file to the new sudo user.
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

# Additional public keys to add to the new sudo user
# OTHER_PUBLIC_KEYS_TO_ADD=(
#     "ssh-rsa AAAAB..."
#     "ssh-rsa AAAAB..."
# )
OTHER_PUBLIC_KEYS_TO_ADD=(
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEfEcJ7FoQYKV0fjjl22Rcf55MJkUvYk/ML8bcJTIEfJzmRHe8xWzZhadbFzwx3G+RC6m3nZahwCHJUfrtELEccjORDICP5HZFErtxWntzm+ycJiJwjp/laQpkc8NQDphSk+gTWM5zN1XDi/7A0Iv1qN5DUofLrU4GlIQZXeekjwNbTEK9GGPU6+W3HZZyYd4ooFmas+sK/pX2QU/poC1XrV5denw1In4jXaZywHOcz7rBvUga181T6TiQyCJ2KJLyXGWHpyS+hasHdAJiThN2HtXLLBAQqBAot6dtioFx0QtBaOmDLrd3WKT/vRHNC7CKa4jQF+Vlrz89ME0M6ALBNp0Egq/OCQI4pavJt8cahTiwmCSwVQv/8o9fKspmJ+YimveWCuMYTOlc4DNJdt1m1cH+9n2WC00nKsUwCklshQ0ZDJJdGLVL2c39IDdgex09vdkH57p4yTiUwgy3weSVODrMnP1S8MUZ5ZokwcfBDIrhql8r93zAr0bbLh6nar9XMU4gSA5UD5zjZtxpN4j0J7K+CKpOvvKN2WCIXe1ek4FRGVA2UlxCIK6PzCof+AglaOTImr4lXXzoT9229QFqDkEb060f2f+vsEVan7jjvVgj3/5ngclKMafULSd+aGckzoIzITVAd2h7yGFnpyVlnVE1Xp33yEnkNnlOR17MGQ== berczi.sandor@gmail.com"
)

####################
### SCRIPT LOGIC ###
####################

# Add sudo user and grant privileges
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"

# Check whether the root account has a real password set
encrypted_root_pw="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

if [ "${encrypted_root_pw}" != "*" ]; then
    # Transfer auto-generated root password to user if present
    # and lock the root account to password-based access
    echo "${USERNAME}:${encrypted_root_pw}" | chpasswd --encrypted
    passwd --lock root
else
    # Delete invalid password for user if using keys so that a new password
    # can be set without providing a previous value
    passwd --delete "${USERNAME}"
fi

# Expire the sudo user's password immediately to force a change
chage --lastday 0 "${USERNAME}"

# Create SSH directory for sudo user
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
fi

# Add additional provided public keys
for pub_key in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
    echo "${pub_key}" >> "${home_directory}/.ssh/authorized_keys"
done

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

# Add exception for SSH and then enable UFW firewall
ufw allow OpenSSH
ufw --force enable
