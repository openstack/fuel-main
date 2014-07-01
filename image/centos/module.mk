$(BUILD_DIR)/image/centos/build.done: $(BUILD_DIR)/mirror/build.done

$(BUILD_DIR)/image/centos/build.done: SANDBOX:=$(BUILD_DIR)/image/centos/SANDBOX
$(BUILD_DIR)/image/centos/build.done: export SANDBOX_UP:=$$(SANDBOX_UP)
$(BUILD_DIR)/image/centos/build.done: export SANDBOX_DOWN:=$$(SANDBOX_DOWN)

$(BUILD_DIR)/image/centos/build.done:
	sudo sh -c "$$$${SANDBOX_UP}"
	sudo yum -c $$(SANDBOX)/etc/yum.conf --installroot=$$(SANDBOX) -y --nogpgcheck install tar python-setuptools git python-imgcreate
	sudo cp $(SOURCE_DIR)/image/centos/build_image.py $$(SANDBOX)/build_image.py
	sudo cp $(SOURCE_DIR)/image/centos/centos6.ks $$(SANDBOX)/centos6.ks
	sudo sed -i -e "s/will_be_substituted_with_centos_repo_baseurl/$(LOCAL_MIRROR_CENTOS_OS_BASEURL)/g" $$(SANDBOX)/centos6.ks
	sudo chroot $$(SANDBOX) python build_image.py -c centos6.ks -n centos6 -e --cache /cache -t /tmp
    sudo mv $$(SANDBOX)/centos6.img $(BUILD_DIR)/image/centos/
    sudo mv $$(SANDBOX)/initramfs*.img $(BUILD_DIR)/image/centos/
    sudo mv $$(SANDBOX)/vmlinuz* $(BUILD_DIR)/image/centos/
    $(ACTION.TOUCH)
