#    Copyright 2014 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from proboscis.asserts import assert_equal
from proboscis import test

from fuelweb_test.helpers import common
from fuelweb_test.helpers import checkers
from fuelweb_test.helpers import os_actions
from fuelweb_test.helpers.decorators import log_snapshot_on_error
from fuelweb_test import settings
from fuelweb_test import logger
from fuelweb_test.tests import base_test_case


@test(groups=["thread_non_func_1"])
class DeploySimpleMasterNodeFail(base_test_case.TestBasic):

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["non_functional", "deploy_simple_flat_master_node_fail"])
    def deploy_simple_flat_master_node_fail(self):
        """Deploy cluster in simple mode with flat nova-network

        Scenario:
            1. Create cluster
            2. Add 1 node with controller role
            3. Add 1 node with compute role
            4. Deploy the cluster
            5. Validate cluster was set up correctly, there are no dead
            services, there are no errors in logs
            6. Verify networks
            7. Verify network configuration on controller
            8. Run OSTF
            9. Shut down master node
            10. Run openstack verification

        """
        self.env.revert_snapshot("ready_with_3_slaves")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            mode=settings.DEPLOYMENT_MODE_SIMPLE
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['compute']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)
        controller_ip = self.fuel_web.get_nailgun_node_by_name(
            'slave-01')['ip']
        os_conn = os_actions.OpenStackActions(controller_ip)
        self.fuel_web.assert_cluster_ready(
            os_conn, smiles_count=6, networks_count=1, timeout=300)

        self.fuel_web.verify_network(cluster_id)
        logger.info('PASS DEPLOYMENT')
        self.fuel_web.run_ostf(
            cluster_id=cluster_id)
        logger.info('PASS OSTF')

        logger.info('Destroy admin node...')
        self.env.nodes().admin.destroy()
        logger.info('Admin node destroyed')

        common_func = common.Common(
            controller_ip,
            settings.SERVTEST_USERNAME,
            settings.SERVTEST_PASSWORD,
            settings.SERVTEST_TENANT)

        # create instance
        server = common_func.create_instance()

        # get_instance details
        details = common_func.get_instance_detail(server)
        assert_equal(details.name, 'test_instance')

        # Check if instacne active
        common_func.verify_instance_status(server, 'ACTIVE')

        # delete instance
        common_func.delete_instance(server)

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_5],
          groups=["deploy_ha_flat_dns_ntp"])
    @log_snapshot_on_error
    def deploy_ha_flat_dns_ntp(self):
        """Use external ntp in ha mode

        Scenario:
            1. Create cluster
            2  Configure external NTP,DNS settings
            3. Add 3 nodes with controller roles
            4. Add 2 nodes with compute roles
            5. Deploy the cluster

        """

        self.env.revert_snapshot("ready_with_5_slaves")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            mode=settings.DEPLOYMENT_MODE_HA,
            settings={
                'ntp_list': settings.EXTERNAL_NTP,
                'dns_list': settings.EXTERNAL_DNS
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['controller'],
                'slave-03': ['controller'],
                'slave-04': ['compute'],
                'slave-05': ['compute']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)
        os_conn = os_actions.OpenStackActions(self.fuel_web.
                                              get_public_vip(cluster_id))
        self.fuel_web.assert_cluster_ready(
            os_conn, smiles_count=16, networks_count=1, timeout=300)
        self.env.make_snapshot("deploy_ha_flat_dns_ntp", is_make=True)

    @test(depends_on=[deploy_ha_flat_dns_ntp],
          groups=["external_dns_ha_flat"])
    @log_snapshot_on_error
    def external_dns_ha_flat(self):
        """Use external dns in ha mode

        Scenario:
            1. Revert cluster
            2. Shutdown dnsmasq
            3. Check dns resolution

        """

        self.env.revert_snapshot("deploy_ha_flat_dns_ntp")

        node_ip = self.fuel_web.get_nailgun_node_by_name(
            'slave-01')['ip']
        remote = self.env.get_admin_remote()
        remote_slave = self.env.get_ssh_to_remote(node_ip)
        remote.execute("dockerctl shell cobbler killall dnsmasq")
        checkers.external_dns_check(remote_slave)

    @test(depends_on=[deploy_ha_flat_dns_ntp],
          groups=["external_ntp_ha_flat"])
    @log_snapshot_on_error
    def external_ntp_ha_flat(self):
        """Use external ntp in ha mode

        Scenario:
            1. Create cluster
            2. Shutdown ntpd
            3. Check ntp update

        """

        self.env.revert_snapshot("deploy_ha_flat_dns_ntp")

        cluster_id = self.fuel_web.client.get_cluster_id(
            self.__class__.__name__)
        remote = self.env.get_admin_remote()
        node_ip = self.fuel_web.get_nailgun_node_by_name(
            'slave-01')['ip']
        remote_slave = self.env.get_ssh_to_remote(node_ip)
        vip = self.fuel_web.get_public_vip(cluster_id)
        remote.execute("pkill -9 ntpd")
        checkers.external_ntp_check(remote_slave, vip)
