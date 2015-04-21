#
# Build directives. Can be overrided by environment variables.
#

# Base path for build and mirror directories.
# Default value: current directory
TOP_DIR?=$(PWD)
TOP_DIR:=$(abspath $(TOP_DIR))
# Working build directory
BUILD_DIR?=$(TOP_DIR)/build
BUILD_DIR:=$(abspath $(BUILD_DIR))
# Path for build artifacts
ARTS_DIR?=$(BUILD_DIR)/artifacts
ARTS_DIR:=$(abspath $(ARTS_DIR))
# Path for cache of downloaded packages
LOCAL_MIRROR?=$(TOP_DIR)/local_mirror
LOCAL_MIRROR:=$(abspath $(LOCAL_MIRROR))
# Path to pre-built artifacts
DEPS_DIR?=$(TOP_DIR)/deps
DEPS_DIR:=$(abspath $(DEPS_DIR))

PRODUCT_VERSION:=6.1

# This variable is used for naming of auxillary objects
# related to product: repositories, mirrors etc
PRODUCT_NAME:=mos

# This variable is used mostly for
# keeping things uniform. Some files
# contain versions as a part of their paths
# but building process for current version differs from
# ones for other versions which are supposed
# to come from DEPS_DIR "as is"
CURRENT_VERSION:=$(PRODUCT_VERSION)

PACKAGE_VERSION=6.1.0
UPGRADE_VERSIONS?=$(CURRENT_VERSION)

# Path to pre-built artifacts
DEPS_DIR_CURRENT?=$(DEPS_DIR)/$(CURRENT_VERSION)
DEPS_DIR_CURRENT:=$(abspath $(DEPS_DIR_CURRENT))

# Artifacts names
ISO_NAME?=fuel-$(PRODUCT_VERSION)
UPGRADE_TARBALL_NAME?=fuel-$(PRODUCT_VERSION)-upgrade
OPENSTACK_PATCH_TARBALL_NAME?=fuel-$(PRODUCT_VERSION)-patch
VBOX_SCRIPTS_NAME?=vbox-scripts-$(PRODUCT_VERSION)
BOOTSTRAP_ART_NAME?=bootstrap.tar.gz
DOCKER_ART_NAME?=fuel-images.tar.lrz
VERSION_YAML_ART_NAME?=version.yaml
CENTOS_REPO_ART_NAME?=centos-repo.tar
UBUNTU_REPO_ART_NAME?=ubuntu-repo.tar
PUPPET_ART_NAME?=puppet.tgz
OPENSTACK_YAML_ART_NAME?=openstack.yaml
TARGET_UBUNTU_IMG_ART_NAME?=ubuntu_target_images.tar
TARGET_CENTOS_IMG_ART_NAME?=centos_target_images.tar



# Where we put artifacts
ISO_PATH:=$(ARTS_DIR)/$(ISO_NAME).iso
IMG_PATH:=$(ARTS_DIR)/$(ISO_NAME).img
UPGRADE_TARBALL_PATH:=$(ARTS_DIR)/$(UPGRADE_TARBALL_NAME).tar
VBOX_SCRIPTS_PATH:=$(ARTS_DIR)/$(VBOX_SCRIPTS_NAME).zip

MASTER_IP?=10.20.0.2
MASTER_DNS?=10.20.0.1
MASTER_NETMASK?=255.255.255.0
MASTER_GW?=10.20.0.1

CENTOS_MAJOR:=6
CENTOS_MINOR:=5
CENTOS_RELEASE:=$(CENTOS_MAJOR).$(CENTOS_MINOR)
CENTOS_ARCH:=x86_64
CENTOS_IMAGE_RELEASE:=$(CENTOS_MAJOR)$(CENTOS_MINOR)
UBUNTU_RELEASE:=trusty
UBUNTU_MAJOR:=14
UBUNTU_MINOR:=04
UBUNTU_RELEASE_NUMBER:=$(UBUNTU_MAJOR).$(UBUNTU_MINOR)
UBUNTU_KERNEL_FLAVOR?=lts-trusty
UBUNTU_NETBOOT_FLAVOR?=netboot
UBUNTU_ARCH:=amd64
UBUNTU_IMAGE_RELEASE:=$(UBUNTU_MAJOR)$(UBUNTU_MINOR)
SEPARATE_IMAGES?=/boot,ext2 /,ext4

# Rebuld packages locally (do not use upstream versions)
BUILD_PACKAGES?=1

# Build OpenStack packages from external sources (do not use prepackaged versions)
# Enter the comma-separated list of OpenStack packages to build, or '0' otherwise.
# Example: BUILD_OPENSTACK_PACKAGES=neutron,keystone
BUILD_OPENSTACK_PACKAGES?=0

# Do not compress javascript and css files
NO_UI_OPTIMIZE:=0

# Define a set of defaults for each OpenStack package
# For each component defined in BUILD_OPENSTACK_PACKAGES variable, this routine will set
# the following variables (i.e. for 'BUILD_OPENSTACK_PACKAGES=neutron'):
# NEUTRON_REPO, NEUTRON_COMMIT, NEUTRON_SPEC_REPO, NEUTRON_SPEC_COMMIT,
# NEUTRON_GERRIT_URL, NEUTRON_GERRIT_COMMIT, NEUTRON_GERRIT_URL,
# NEUTRON_SPEC_GERRIT_URL, NEUTRON_SPEC_GERRIT_COMMIT
define set_vars
    $(call uc,$(1))_REPO?=https://github.com/openstack/$(1).git
    $(call uc,$(1))_COMMIT?=master
    $(call uc,$(1))_SPEC_REPO?=https://review.fuel-infra.org/openstack-build/$(1)-build.git
    $(call uc,$(1))_SPEC_COMMIT?=master
    $(call uc,$(1))_GERRIT_URL?=https://review.openstack.org/openstack/$(1).git
    $(call uc,$(1))_GERRIT_COMMIT?=none
    $(call uc,$(1))_SPEC_GERRIT_URL?=https://review.fuel-infra.org/openstack-build/$(1)-build.git
    $(call uc,$(1))_SPEC_GERRIT_COMMIT?=none
endef

# Repos and versions
FUELLIB_COMMIT?=master
NAILGUN_COMMIT?=master
PYTHON_FUELCLIENT_COMMIT?=master
ASTUTE_COMMIT?=master
OSTF_COMMIT?=master

FUELLIB_REPO?=https://github.com/stackforge/fuel-library.git
NAILGUN_REPO?=https://github.com/stackforge/fuel-web.git
PYTHON_FUELCLIENT_REPO?=https://github.com/stackforge/python-fuelclient.git
ASTUTE_REPO?=https://github.com/stackforge/fuel-astute.git
OSTF_REPO?=https://github.com/stackforge/fuel-ostf.git

# Gerrit URLs and commits
FUELLIB_GERRIT_URL?=https://review.openstack.org/stackforge/fuel-library
NAILGUN_GERRIT_URL?=https://review.openstack.org/stackforge/fuel-web
PYTHON_FUELCLIENT_GERRIT_URL?=https://review.openstack.org/stackforge/python-fuelclient
ASTUTE_GERRIT_URL?=https://review.openstack.org/stackforge/fuel-astute
OSTF_GERRIT_URL?=https://review.openstack.org/stackforge/fuel-ostf

FUELLIB_GERRIT_COMMIT?=none
NAILGUN_GERRIT_COMMIT?=none
PYTHON_FUELCLIENT_GERRIT_COMMIT?=none
ASTUTE_GERRIT_COMMIT?=none
OSTF_GERRIT_COMMIT?=none

LOCAL_MIRROR_CENTOS:=$(LOCAL_MIRROR)/centos
LOCAL_MIRROR_CENTOS_OS_BASEURL:=$(LOCAL_MIRROR_CENTOS)/os/$(CENTOS_ARCH)
LOCAL_MIRROR_UBUNTU:=$(LOCAL_MIRROR)/ubuntu
LOCAL_MIRROR_UBUNTU_OS_BASEURL:=$(LOCAL_MIRROR_UBUNTU)
LOCAL_MIRROR_DOCKER:=$(LOCAL_MIRROR)/docker
LOCAL_MIRROR_DOCKER_BASEURL:=$(LOCAL_MIRROR_DOCKER)

# Use mirror.fuel-infra.org mirror by default. Other possible values are
# 'msk', 'srt', 'usa', 'hrk', 'usa', 'cz'.
# Setting any other value or removing of this variable will cause
# download of all the packages directly from internet

# It is possible to define several repositories with priorities.
# First repository is used to download boot and installer files.
# MULTI_MIRROR_CENTOS:=repo1_name,repo1_priority,repo1_uri repo2_name,repo2_priority,repo2_uri

USE_MIRROR?=ext
ifeq ($(USE_MIRROR),ext)
MULTI_MIRROR_CENTOS?=\
ext,1,http://mirror.fuel-infra.org/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=mirror.fuel-infra.org
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://mirror.fuel-infra.org/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),srt)
MULTI_MIRROR_CENTOS?=\
srt,1,http://osci-mirror-srt.srt.mirantis.net/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=osci-mirror-srt.srt.mirantis.net
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://osci-mirror-srt.srt.mirantis.net/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),msk)
MULTI_MIRROR_CENTOS?=\
msk,1,http://osci-mirror-msk.msk.mirantis.net/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=osci-mirror-msk.msk.mirantis.net
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://osci-mirror-msk.msk.mirantis.net/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),hrk)
MULTI_MIRROR_CENTOS?=\
kha,1,http://osci-mirror-kha.kha.mirantis.net/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=osci-mirror-kha.kha.mirantis.net
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://osci-mirror-kha.kha.mirantis.net/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),usa)
MULTI_MIRROR_CENTOS?=\
usa,1,http://mirror.seed-us1.fuel-infra.org/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=mirror.seed-us1.fuel-infra.org
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://mirror.seed-us1.fuel-infra.org/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),cz)
MULTI_MIRROR_CENTOS?=\
cz,1,http://mirror.seed-cz1.fuel-infra.org/fwm/$(PRODUCT_VERSION)/centos/os/$(CENTOS_ARCH)
MIRROR_UBUNTU?=mirror.seed-cz1.fuel-infra.org
MIRROR_UBUNTU_PRODUCT_ROOT?=/$(PRODUCT_NAME)/ubuntu/
MIRROR_UBUNTU_UPSTREAM_ROOT?=/pkgs/ubuntu/
MIRROR_UBUNTU_METHOD?=http
MIRROR_UBUNTU_SECTION?=main,restricted
MIRROR_DOCKER?=http://mirror.seed-cz1.fuel-infra.org/fwm/$(PRODUCT_VERSION)/docker
endif
ifeq ($(USE_MIRROR),none)
MIRROR_FUEL?=http://osci-obs.vm.mirantis.net:82/centos-fuel-$(PRODUCT_VERSION)-stable/centos
MULTI_MIRROR_CENTOS?=\
os,10,http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)/os/$(CENTOS_ARCH) \
updates,10,http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)/updates/$(CENTOS_ARCH) \
extras,10,http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)/extras/$(CENTOS_ARCH) \
centosplus,10,http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)/centosplus/$(CENTOS_ARCH) \
contrib,10,http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)/contrib/$(CENTOS_ARCH) \
fuel,1,$(MIRROR_FUEL)
# We use Centos 6.6 boot and installer file while other files and packages
# come from Centos $(CENTOS_RELEASE). We need this due to this
# https://bugs.launchpad.net/fuel/+bug/1393414
MIRROR_CENTOS_KERNEL_BASEURL?=http://mirror.centos.org/centos-6/6.6/os/$(CENTOS_ARCH)
# USE_MIRROR=none mode is ONLY used for building centos mirror, not for building ISO.
# That is why Ubuntu mirror variables are skipped here.
endif

YUM_DOWNLOAD_SRC?=

REQUIRED_RPMS:=$(shell grep -v "^\\s*\#" $(SOURCE_DIR)/requirements-rpm.txt)
REQUIRED_DEBS:=$(shell grep -v "^\\s*\#" $(SOURCE_DIR)/requirements-deb.txt)

# Comma or space separated list. Available feature groups:
#   experimental - allow experimental options
#   mirantis - enable Mirantis logos and support page
FEATURE_GROUPS?=experimental
comma:=,
FEATURE_GROUPS:=$(subst $(comma), ,$(FEATURE_GROUPS))

# INTEGRATION TEST CONFIG
NOFORWARD:=1

# Path to yaml configuration file to build ISO ks.cfg
KSYAML?=$(SOURCE_DIR)/iso/ks.yaml

# Docker prebuilt containers. Default is to build containers during ISO build
DOCKER_PREBUILT?=0

# Source of docker prebuilt containers archive. Works only if DOCKER_PREBUILT=true
# Examples:
# DOCKER_PREBUILT_SOURCE=http://srv11-msk.msk.mirantis.net/docker-test/fuel-images.tar.lrz
# DOCKER_PREBUILT_SOURCE=/var/fuel-images.tar.lrz make docker
DOCKER_PREBUILT_SOURCE?=http://srv11-msk.msk.mirantis.net/docker-test/fuel-images.tar.lrz

# Production variable (prod, dev, docker)
PRODUCTION?=docker

SANDBOX_MIRROR_CENTOS_UPSTREAM?=http://mirrors-local-msk.msk.mirantis.net/centos-$(PRODUCT_VERSION)/$(CENTOS_RELEASE)
SANDBOX_MIRROR_CENTOS_UPSTREAM_OS_BASEURL:=$(SANDBOX_MIRROR_CENTOS_UPSTREAM)/os/$(CENTOS_ARCH)/
SANDBOX_MIRROR_CENTOS_UPDATES_OS_BASEURL:=$(SANDBOX_MIRROR_CENTOS_UPSTREAM)/updates/$(CENTOS_ARCH)/
SANDBOX_MIRROR_EPEL?=http://mirror.yandex.ru/epel/
SANDBOX_MIRROR_EPEL_OS_BASEURL:=$(SANDBOX_MIRROR_EPEL)/$(CENTOS_MAJOR)/$(CENTOS_ARCH)/
