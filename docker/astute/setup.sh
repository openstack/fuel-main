#!/bin/bash

rm -rf /etc/yum.repos.d/*

cat << EOF > /etc/yum.repos.d/nailgun.repo
[nailgun]
name=Nailgun Local Repo
baseurl=http://$(route -n | awk '/^0.0.0.0/ {print $2}'):${DOCKER_PORT}/os/x86_64/
gpgcheck=0
EOF

yum clean expire-cache
yum update -y
yum install -y --quiet nailgun-mcagents sysstat


puppet apply --detailed-exitcodes -d -v /etc/puppet/modules/nailgun/examples/astute-only.pp || [[ $? == 2 ]]
systemctl enable supervisord.service

cat << EOF > /etc/yum.repos.d/nailgun.repo
[nailgun]
name=Nailgun Local Repo
baseurl=file:/var/www/nailgun/centos/x86_64
gpgcheck=0
EOF

yum clean all


systemctl enable start-container.service
