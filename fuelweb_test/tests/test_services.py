#    Copyright 2013 Mirantis, Inc.
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

import logging

from proboscis import test, SkipTest
from proboscis.asserts import assert_true


from fuelweb_test.helpers import checkers, services_prepare
from fuelweb_test.helpers.common import Common
from fuelweb_test.helpers.decorators import debug, log_snapshot_on_error
from fuelweb_test.tests import base_test_case
from fuelweb_test import settings


LOGGER = logging.getLogger(__name__)
LOGWRAP = debug(LOGGER)


@test(groups=["services", "services.savanna"])
class SavannaSimple(base_test_case.TestBasic):
    """
    Don't recommend to start tests without kvm
    Put Savanna image before start
    """
    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["deploy_savanna_simple"])
    @log_snapshot_on_error
    def deploy_savanna_simple(self):
        """Deploy cluster in simple mode with Savanna

        Scenario:
            1. Create cluster. Set install Savanna option
            2. Add 1 node with controller role
            3. Add 1 node with compute role
            4. Deploy the cluster
            5. Verify savanna services
            6. Register savanna image
            7. Run OSTF
            8. Run OSTF platform tests

        Snapshot: deploy_savanna_simple

        """
        services_prepare.savanna_check_image()

        LOGGER.debug('Check slaves RAM size')
        if settings.HARDWARE["slave_node_memory"] < 1500:
            LOGGER.error("Slaves node memory is low, need more then 1.5Gb")
            assert_true(False)

        self.env.revert_snapshot("ready_with_3_slaves")
        services_prepare.services_prepare_lab(
            self.fuel_web, self.env, self.__class__.__name__,
            {'savanna': True}, ['savanna-api'], 6)

        services_prepare.savanna_prepare_env(self.fuel_web)

        test_classes = ['fuel_health.tests.sanity.test_sanity_savanna.'
                        'SanitySavannaTests.test_sanity_savanna']
        self.fuel_web.run_ostf(
            cluster_id=self.fuel_web.get_last_created_cluster(),
            tests_must_be_passed=test_classes
        )

        LOGGER.debug('Run OSTF platform tests')
        test_classes = ['fuel_health.tests.platform_tests'
                        '.test_platform_savanna.'
                        'PlatformSavannaTests.test_platform_savanna']
        self.fuel_web.run_ostf(
            cluster_id=self.fuel_web.get_last_created_cluster(),
            tests_must_be_passed=test_classes, test_sets=['platform_tests'])


        self.env.make_snapshot("deploy_savanna_simple")


@test(groups=["services", "services.murano"])
class MuranoSimple(base_test_case.TestBasic):
    """
    Don't recommend to start tests without kvm
    Put Murano image before start
    Murano OSTF platform tests  without Internet connection will be failed
    """
    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["deploy_murano_simple"])
    @log_snapshot_on_error
    def deploy_murano_simple(self):
        """Deploy cluster in simple mode with Murano

        Scenario:
            1. Create cluster. Set install Murano option
            2. Add 1 node with controller role
            3. Add 1 nodes with compute role
            4. Deploy the cluster
            5. Verify murano services
            6. Register murano image
            7. Run OSTF
            8. Run OSTF platform tests

        Snapshot: deploy_murano_simple

        """
        if settings.OPENSTACK_RELEASE == settings.OPENSTACK_RELEASE_REDHAT:
            raise SkipTest()

        LOGGER.debug('Check slaves RAM size')
        if settings.HARDWARE["slave_node_memory"] < 5000:
            LOGGER.error('Slaves node memory is low, need more then 5Gb')
            assert_true(False)

        LOGGER.debug('Check MD5 of image')
        check_image = checkers.check_image(
            settings.SERVTEST_MURANO_SERVER_URL,
            settings.SERVTEST_MURANO_IMAGE,
            settings.SERVTEST_MURANO_IMAGE_MD5,
            settings.SERVTEST_LOCAL_PATH)
        assert_true(check_image)

        self.env.revert_snapshot("ready_with_3_slaves")

        services_prepare.services_prepare_lab(
            self.fuel_web, self.env, self.__class__.__name__,
            {'murano': True, "net_provider": 'neutron',
             "net_segment_type": 'gre'},
            ['murano-api', 'muranoconductor'], 5)

        controller_ip = self.fuel_web.get_nailgun_node_by_name(
            'slave-01')['ip']
        common_func = Common(controller_ip,
                             settings.SERVTEST_USERNAME,
                             settings.SERVTEST_PASSWORD,
                             settings.SERVTEST_TENANT)

        LOGGER.debug('Import image')
        common_func.image_import(
            settings.SERVTEST_LOCAL_PATH,
            settings.SERVTEST_MURANO_IMAGE,
            settings.SERVTEST_MURANO_IMAGE_NAME,
            settings.SERVTEST_MURANO_IMAGE_META)
        LOGGER.debug('Permit all traffic')
        common_func.goodbye_security()
        LOGGER.debug('Create key murano-lb-key')
        common_func.create_key('murano-lb-key')

        LOGGER.debug('Run sanity and functional OSTF tests')
        test_classes = ['fuel_health.tests.sanity.test_sanity_murano.'
                        'MuranoSanityTests.test_create_and_delete_service']
        self.fuel_web.run_ostf(
            cluster_id=self.fuel_web.get_last_created_cluster(),
            tests_must_be_passed=test_classes
        )

        LOGGER.debug('Run OSTF platform tests')
        test_class_main = ('fuel_health.tests.platform_tests'
                           '.test_murano.MuranoDeploymentSmokeTests')
        tests_names = ['test_deploy_demo_service',
                       'test_deploy_telnet_service',
                       'test_deploy_apache_service']
        test_classes = []
        for test_name in tests_names:
            test_classes.append('{0}.{1}'.format(test_class_main,
                                                 test_name))

        self.fuel_web.run_ostf(
            cluster_id=self.fuel_web.get_last_created_cluster(),
            tests_must_be_passed=test_classes, test_sets=['platform_tests'])
        self.env.make_snapshot("deploy_murano_simple")


@test(groups=["thread_1", "services", "services.ceilometer"])
class CeilometerSimple(base_test_case.TestBasic):

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["deploy_ceilometer_simple"])
    @log_snapshot_on_error
    def deploy_ceilometer_simple(self):
        """Deploy cluster in simple mode with Ceilometer

        Scenario:
            1. Create cluster. Set install Ceilometer option
            2. Add 1 node with controller role
            3. Add 1 nodes with compute role
            4. Add 1 node with cinder role
            4. Deploy the cluster
            5. Verify ceilometer api is running
            6. Run ostf

        Snapshot: deploy_ceilometer_simple

        """
        if settings.OPENSTACK_RELEASE == settings.OPENSTACK_RELEASE_REDHAT:
            raise SkipTest()

        self.env.revert_snapshot("ready_with_3_slaves")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            settings={
                'ceilometer': True
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['compute'],
                'slave-03': ['compute']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)

        checkers.verify_service(
            self.env.get_ssh_to_remote_by_name("slave-01"),
            service_name='ceilometer-api')

        # run ostf smoke and sanity
        self.fuel_web.run_ostf(
            cluster_id=cluster_id,
            should_fail=1)

        # verify if needed image exists
        LOGGER.debug('Check MD5 of image')
        check_image = checkers.check_image(
            settings.SERVTEST_HEAT_SERVER_URL,
            settings.SERVTEST_HEAT_IMAGE,
            settings.SERVTEST_HEAT_IMAGE_MD5,
            settings.SERVTEST_LOCAL_PATH)
        assert_true(check_image)

        controller_ip = self.fuel_web.get_nailgun_node_by_name(
            'slave-01')['ip']
        common_func = Common(controller_ip,
                             settings.SERVTEST_USERNAME,
                             settings.SERVTEST_PASSWORD,
                             settings.SERVTEST_TENANT)

        LOGGER.debug('Import image')
        common_func.image_import(
            settings.SERVTEST_LOCAL_PATH,
            settings.SERVTEST_HEAT_IMAGE,
            settings.SERVTEST_HEAT_IMAGE_NAME,
            settings.SERVTEST_HEAT_IMAGE_META)

        # run ostf platform tests for ceilometer and heat

        self.fuel_web.run_ostf(
            cluster_id=cluster_id,  test_sets=['platform_tests'],
            should_fail=1, timeout=3500)

        self.env.make_snapshot("deploy_ceilometer_simple")


@test(groups=["services", "services.ceilometer"])
class CeilometerSimpleMongo(base_test_case.TestBasic):

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_5])
    def verify_mongo_role_available(self):
        """Check if mongo role available
        Scenario:
            1. Revert ready 5 slave environment
            2. Check if mongo role is available

        Snapshot: deploy_mongo_available

        """
        if settings.OPENSTACK_RELEASE == settings.OPENSTACK_RELEASE_REDHAT:
            raise SkipTest()

        self.env.revert_snapshot("ready_with_5_slaves")
        try:
            self.fuel_web.assert_release_role_present(
                settings.OPENSTACK_RELEASE, role_name='mongo')
        except AssertionError:
            LOGGER.debug('Mongo role is not implemented')
            LOGGER.debug(AssertionError)
            raise SkipTest()

        self.env.make_snapshot("deploy_mongo_available")

    @test(depends_on=[verify_mongo_role_available],
          groups=["deploy_ceilometer_simple_with_mongo"])
    @log_snapshot_on_error
    def deploy_ceilometer_simple_with_mongo(self):
        """Deploy cluster in simple mode with Ceilometer

        Scenario:
            1. Create cluster. Set install Ceilometer option
            2. Add 1 node with controller role
            3. Add 1 nodes with compute role
            4. Add 1 node with cinder role
            5. Add 1 node with mongo role
            6. Deploy the cluster
            7. Verify ceilometer api is running
            8. Run ostf

        Snapshot: deploy_ceilometer_simple_with_mongo

        """
        self.env.revert_snapshot("deploy_mongo_available")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            settings={
                'ceilometer': True
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['compute'],
                'slave-03': ['cinder'],
                'slave-04': ['mongo']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)

        checkers.verify_service(
            self.env.get_ssh_to_remote_by_name("slave-01"),
            service_name='ceilometer-api')

        # run ostf smoke and sanity
        self.fuel_web.run_ostf(
            cluster_id=cluster_id,
            should_fail=0)

        self.fuel_web.run_ostf(
            cluster_id=cluster_id,  test_sets=['platform_tests'],
            should_fail=2, timeout=3500)

        self.env.make_snapshot("deploy_ceilometer_simple_with_mongo")

    @test(depends_on=[verify_mongo_role_available],
          groups=["deploy_ceilometer_ha_with_mongo"])
    @log_snapshot_on_error
    def deploy_ceilometer_ha_with_mongo(self):
        """Deploy cluster in simple mode with Ceilometer

        Scenario:
            1. Create cluster. Set install Ceilometer option
            2. Add 3 node with controller role
            3. Add 1 nodes with compute role
            4. Add 1 node with mongo role
            5. Deploy the cluster
            6. Verify ceilometer api is running
            7. Run ostf

        Snapshot: deploy_ceilometer_ha_with_mongo

        """

        self.env.revert_snapshot("deploy_mongo_available")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            settings={
                'ceilometer': True
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['controller'],
                'slave-03': ['controller'],
                'slave-04': ['compute'],
                'slave-05': ['mongo']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)

        checkers.verify_service(
            self.env.get_ssh_to_remote_by_name("slave-01"),
            service_name='ceilometer-api')

        # run ostf smoke and sanity
        self.fuel_web.run_ostf(
            cluster_id=cluster_id,
            should_fail=1)

        # run ostf platform

        self.fuel_web.run_ostf(
            cluster_id=cluster_id,  test_sets=['platform_tests', 'ha'],
            should_fail=2, timeout=3500)

        self.env.make_snapshot("deploy_ceilometer_ha_with_mongo")

    @test(depends_on=[verify_mongo_role_available],
          groups=["deploy_ceilometer_simple_multirole"])
    @log_snapshot_on_error
    def deploy_ceilometer_simple_multirole(self):
        """Deploy cluster in simple multirole mode with Ceilometer

        Scenario:
            1. Create cluster. Set install Ceilometer option
            2. Add 1 node with controller role
            3. Add 1 nodes with compute role
            4. Add 2 nodes with cinder and mongo roles
            5. Deploy the cluster
            6. Verify ceilometer api is running
            7. Run ostf

        Snapshot: deploy_ceilometer_simple_multirole

        """
        self.env.revert_snapshot("deploy_mongo_available")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            settings={
                'ceilometer': True
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['compute'],
                'slave-03': ['cinder', 'mongo'],
                'slave-04': ['cinder', 'mongo']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)

        checkers.verify_service(
            self.env.get_ssh_to_remote_by_name("slave-01"),
            service_name='ceilometer-api')

        # run ostf smoke and sanity
        self.fuel_web.run_ostf(
            cluster_id=cluster_id,
            should_fail=0)

        self.fuel_web.run_ostf(
            cluster_id=cluster_id,  test_sets=['platform_tests'],
            should_fail=2, timeout=3500)

        self.env.make_snapshot("deploy_ceilometer_simple_mulirole")

    @test(depends_on=[verify_mongo_role_available],
          groups=["deploy_ceilometer_ha_multirole"])
    @log_snapshot_on_error
    def deploy_ceilometer_ha_multirole(self):
        """Deploy cluster in ha multirole mode with Ceilometer

        Scenario:
            1. Create cluster. Set install Ceilometer option
            2. Add 3 node with controller and mongo roles
            3. Add 1 nodes with compute role
            4. Add 1 nodes with cinder
            5. Deploy the cluster
            6. Verify ceilometer api is running
            7. Run ostf

        Snapshot: deploy_ceilometer_ha_multirole

        """
        self.env.revert_snapshot("deploy_mongo_available")

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            settings={
                'ceilometer': True
            }
        )
        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller', 'mongo'],
                'slave-02': ['controller', 'mongo'],
                'slave-03': ['controller', 'mongo'],
                'slave-04': ['compute'],
                'slave-05': ['cinder']
            }
        )
        self.fuel_web.deploy_cluster_wait(cluster_id)

        checkers.verify_service(
            self.env.get_ssh_to_remote_by_name("slave-01"),
            service_name='ceilometer-api')

        # run ostf smoke and sanity
        self.fuel_web.run_ostf(
            cluster_id=cluster_id,
            should_fail=0)

        self.fuel_web.run_ostf(
            cluster_id=cluster_id,  test_sets=['platform_tests', 'ha'],
            should_fail=2, timeout=3500)

        self.env.make_snapshot("deploy_ceilometer_ha_mulirole")
