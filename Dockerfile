# Step 1: Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Step 2: Set environment variables to prevent interaction
ENV DEBIAN_FRONTEND=noninteractive

# Step 3: Change the root password to 'ubuntu'
RUN echo "root:ubuntu" | chpasswd

# Step 4: Log in as root user, switch to home directory, and update apt package index
USER root
WORKDIR /root

# Step 5: Install necessary tools (added lsb-release and bc, removed sudo)
RUN apt-get update && \
    apt-get install -y cron git lsb-release bc

# Step 6: Clone the DHIS2 server tools repository
RUN git clone https://github.com/okothmax/dhsi2-server-tools-2

# Step 7: Copy the hosts.template file to hosts
RUN cp dhsi2-server-tools-2/deploy/inventory/hosts.template dhsi2-server-tools-2/deploy/inventory/hosts

# Step 8: Overwrite the contents of the hosts file with your required configuration
RUN echo "\
127.0.0.1\n\n\
[web]\n\
proxy ansible_host=172.19.2.2\n\n\
[databases]\n\
postgres ansible_host=172.19.2.20\n\n\
[instances]\n\
dhis ansible_host=172.19.2.11 database_host=postgres dhis2_version=2.40 proxy_rewrite=True\n\n\
[monitoring]\n\
monitor ansible_host=172.19.2.30\n\n\
[integration]\n\n\
[all:vars]\n\
fqdn=\n\
email=\n\
timezone=Africa/Nairobi\n\
ansible_connection=lxd\n\
postgresql_version=16\n\
server_monitoring=munin\n\
app_monitoring=glowroot\n\
lxd_network=172.19.2.1/24\n\
lxd_bridge_interface=lxdbr1\n\
guest_os=22.04\n\
guest_os_arch=amd64\n\
proxy=nginx\n\
TLS_TYPE=letsencrypt\n\n\
[instances:vars]\n\
database_host=postgres\n\
create_db=yes\n\
JAVA_VERSION=11\n\
dhis2_version=2.40\n\
dhis2_auto_upgrade=false\n\
unattended_upgrades=yes" > dhsi2-server-tools-2/deploy/inventory/hosts

# Step 9: Change directory to the deploy folder
WORKDIR /root/dhsi2-server-tools-2/deploy/

# Step 10: Replace 'sudo -E' with 'env' and remove other sudo usages in the deploy script
RUN chmod +x deploy.sh && \
    sed -i 's/sudo -E/env/g' deploy.sh && \
    sed -i 's/sudo //g' deploy.sh && \
    ./deploy.sh

# End of Dockerfile
