.PHONY: upgrade fuel-upgrade openstack-patch

upgrade: UPGRADERS ?= "host-system docker bootstrap openstack"
upgrade: $(BUILD_DIR)/upgrade/upgrade.done

#fuel-upgrade: UPGRADERS ?= "host-system docker bootstrap"
#fuel-upgrade: $(BUILD_DIR)/upgrade/fuel.done

# BUILD_ARTIFACTS=0 means 'do not build anything, use files from master extra release'"
BUILD_ARTIFACTS?=1
EXTRA_RELEASES?="master 5.0.x"

OBJECTS?=$(SOURCE_DIR)/objects

openstack-patch: UPGRADERS ?= "openstack"
openstack-patch: $(BUILD_DIR)/upgrade/openstack.done

$(BUILD_DIR)/upgrade/upgrade.done: \
		$(BUILD_DIR)/upgrade/openstack-part.tar \
		$(BUILD_DIR)/upgrade/fuel-part.tar \
		$(BUILD_DIR)/upgrade/common-part.tar
	rm -f $(TARBALL_PATH)
	tar Af $(TARBALL_PATH) $(BUILD_DIR)/upgrade/fuel-part.tar
	tar Af $(TARBALL_PATH) $(BUILD_DIR)/upgrade/openstack-part.tar
	tar Af $(TARBALL_PATH) $(BUILD_DIR)/upgrade/common-part.tar
	# Looks like gzip is useless here
	# gzip $(TARBALL_PATH)
	$(ACTION.TOUCH)

$(BUILD_DIR)/upgrade/venv.done:
	mkdir -p $(BUILD_DIR)/upgrade/venv
	virtualenv $(BUILD_DIR)/upgrade/venv
	# Requires virtualenv, pip, python-dev packages
	$(BUILD_DIR)/upgrade/venv/bin/pip install -r $(BUILD_DIR)/repos/nailgun/fuel_upgrade_system/fuel_upgrade/requirements.txt
	$(BUILD_DIR)/upgrade/venv/bin/pip install $(BUILD_DIR)/repos/nailgun/fuel_upgrade_system/fuel_upgrade

$(BUILD_DIR)/upgrade/common-part.tar: \
		$(BUILD_DIR)/repos/fuellib.done \
		$(BUILD_DIR)/upgrade/venv.done
	rm -f $@
	tar cf $@ -C $(BUILD_DIR)/repos/fuellib/deployment --xform s:^puppet:upgrade/puppet/modules: puppet
	tar rf $@ -C $(BUILD_DIR)/repos/fuellib/deployment/puppet/osnailyfacter/examples --xform s:^:upgrade/puppet/manifests/: site.pp
	tar rf $@ -C $(BUILD_DIR)/upgrade/venv/lib/python* --xform s:^:upgrade/: site-packages
	tar rf $@ -C $(BUILD_DIR)/upgrade/venv --xform s:^:upgrade/: bin/fuel-upgrade
	sed 's/{{UPGRADERS}}/${UPGRADERS}/g' $(SOURCE_DIR)/upgrade/upgrade_template.sh > $(BUILD_DIR)/upgrade/upgrade.sh
	tar rf $@ --mode=755 -C $(BUILD_DIR)/upgrade upgrade.sh

ifneq ($(BUILD_ARTIFACTS),0)
$(BUILD_DIR)/upgrade/fuel-part.tar: $(BUILD_DIR)/iso/iso.done
endif

$(BUILD_DIR)/upgrade/fuel-part.tar:
	mkdir -p $(@D)
	rm -f $@
ifneq ($(BUILD_ARTIFACTS),0)
	tar cf $@ -C $(ISOROOT)/docker/images --xform s:^:upgrade/images/: fuel-images.tar.lrz
	tar rf $@ -C $(BUILD_DIR)/iso/isoroot --xform s:^:upgrade/config/: version.yaml
	tar rf $@ -C $(BUILD_DIR)/bootstrap --xform s:^:upgrade/bootstrap/: initramfs.img linux
else
	mkdir -p $(BUILD_DIR)/upgrade/objects/bootstrap
	tar xf $(OBJECTS)/master/bootstrap.tar.gz -C $(BUILD_DIR)/upgrade/objects/bootstrap
	tar rf $@ -C $(BUILD_DIR)/upgrade/objects/bootstrap --xform s:^:upgrade/bootstrap/: initramfs.img linux
	tar cf $@ -C $(OBJECTS)/master --xform s:^:upgrade/images/: fuel-images.tar.lrz
	tar rf $@ -C $(OBJECTS)/master --xform s:^:upgrade/config/: version.yaml
endif
	$(ACTION.TOUCH)

#fuel_version_$1:=python -c "import yaml; print yaml.load(open('/etc/fuel/version.yaml'))['VERSION']['release']"
define extra-os-part
os_version_$1:=$$(shell python -c "import yaml; print filter(lambda r: r['fields'].get('name'), yaml.load(open('$(OBJECTS)/$1/openstack.yaml')))[0]['fields']['version']")
$(BUILD_DIR)/upgrade/openstack-part.tar: $(BUILD_DIR)/upgrade/openstack-$1-part.tar

$(BUILD_DIR)/upgrade/openstack-$1-part.tar:
	mkdir -p $$(@D)
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1)/modules
	tar xf $(OBJECTS)/$1/manifests.tar.gz -C $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1)/modules
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1)/manifests
	cd $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1) && cp modules/osnailyfacter/examples/site.pp manifests
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/repos/$$(os_version_$1)/centos/x86_64
	tar xf $(OBJECTS)/$1/centos-repo.tar.gz -C $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/repos/$$(os_version_$1)/centos/x86_64
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/repos/$$(os_version_$1)/ubuntu/x86_64
	tar xf $(OBJECTS)/$1/ubuntu-repo.tar.gz -C $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/repos/$$(os_version_$1)/ubuntu/x86_64
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/releases
	cp $(OBJECTS)/$1/openstack.yaml $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/releases/$$(os_version_$1).yaml
	mkdir -p $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1)/manifests/
	cd $(OBJECTS)/$1 && cp centos-versions.yaml ubuntu-versions.yaml $(BUILD_DIR)/upgrade/openstack-$1-part/upgrade/puppet/$$(os_version_$1)/manifests/
	tar cf $$@ -C $(BUILD_DIR)/upgrade/openstack-$1-part/ .
endef

$(foreach object,$(EXTRA_RELEASES),$(eval $(call extra-os-part,$(object))))


ifneq ($(BUILD_ARTIFACTS),0)
$(BUILD_DIR)/upgrade/openstack-part.tar: $(BUILD_DIR)/packages/build.done
endif

$(BUILD_DIR)/upgrade/openstack-part.tar:
	mkdir -p $(@D)
	rm -f $@
ifneq ($(BUILD_ARTIFACTS),0)
	python -c "import yaml; print filter(lambda r: r['fields'].get('name'), yaml.load(open('$(BUILD_DIR)/repos/nailgun/nailgun/nailgun/fixtures/openstack.yaml')))[0]['fields']['version']" > $(BUILD_DIR)/upgrade/os_version
	tar cf $@ -C $(BUILD_DIR)/repos/fuellib/deployment --xform s:^puppet:upgrade/puppet/`cat $(BUILD_DIR)/upgrade/os_version`/modules: puppet
	tar rf $@ -C $(BUILD_DIR)/repos/fuellib/deployment/puppet/osnailyfacter/examples --xform s:^:upgrade/puppet/`cat $(BUILD_DIR)/upgrade/os_version`/manifests/: site.pp
	tar cf $@ -C $(LOCAL_MIRROR) --xform s:^centos/os/x86_64:upgrade/repos/`cat $(BUILD_DIR)/upgrade/os_version`/centos/x86_64: centos/os/x86_64
	tar rf $@ -C $(LOCAL_MIRROR) --xform s:^ubuntu:upgrade/repos/`cat $(BUILD_DIR)/upgrade/os_version`/ubuntu/x86_64: ubuntu
	tar rf $@ -C $(BUILD_DIR)/repos/nailgun/nailgun/nailgun/fixtures/openstack.yaml --xform s:^:upgrade/releases/`cat $(BUILD_DIR)/upgrade/os_version`: openstack.yaml
	tar rf $@ -C $(ISOROOT) --xform s:^:upgrade/puppet/`cat $(BUILD_DIR)/upgrade/os_version`/manifests/: centos-versions.yaml ubuntu-versions.yaml
endif
	tar rf $@ -C $(SOURCE_DIR) upgrade/config/5.0/centos-versions.yaml upgrade/config/5.0/ubuntu-versions.yaml
	$(foreach object,$(EXTRA_RELEASES),tar Af $@ $(BUILD_DIR)/upgrade/openstack-$(object)-part.tar;)

$(BUILD_DIR)/upgrade/fuel.done: \
		$(BUILD_DIR)/upgrade/common-part.tar \
		$(BUILD_DIR)/upgrade/fuel-part.tar
	rm -f $(FUEL_TARBALL_PATH)
	tar Af $(FUEL_TARBALL_PATH) $(BUILD_DIR)/upgrade/fuel-part.tar
	tar Af $(FUEL_TARBALL_PATH) $(BUILD_DIR)/upgrade/common-part.tar
	$(ACTION.TOUCH)

$(BUILD_DIR)/upgrade/openstack.done: \
		$(BUILD_DIR)/upgrade/common-part.tar \
		$(BUILD_DIR)/upgrade/openstack-part.tar
	rm -f $(OS_TARBALL_PATH)
	tar Af $(OS_TARBALL_PATH) $(BUILD_DIR)/upgrade/openstack-part.tar
	tar Af $(OS_TARBALL_PATH) $(BUILD_DIR)/upgrade/common-part.tar
	$(ACTION.TOUCH)
