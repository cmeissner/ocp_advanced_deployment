# OCP Advanced Deployment Homework

This document describe what have been done and what is to do to install ocp cluster with all given Parts.
The given playbook is tested and worked only with OCP version 3.9.x (3.9.41). You also need a *OpenShift HA Homework Lab* found at labs.opentlc.com.

## Installation

To Install the whole environment you need to have complete execution authority and have to become `root`.

```
$ sudo -i
# git clone https://github.com/cmeissner/ocp_advanced_deployment.git
# cd ocp_advanced_deployment
# ansible-playbook -f 30 ansible/install_lab.yaml | tee -a /root/install_lab.log
```

To quarantee that the installation runs complete you may want to start the `ansible-playbook` command inside of `screen` or `tmux`. Please refer documentation of these tools to know how to use it.

## Target Environment

The starting point is `ansible/install_lab.yaml` inside the git repository. All tasks to setup the PoC are included here.

* SETUP_GUID
  takes care of the availability of the environment variable GUID on all lab hosts.
* PREREQ_CHECKS
  checks whether all pre requirements are met.
* INSTALL_REQUIREMENTS
  installs missing packages which are absolutly required.
* CREATE_HOST_FILE
  place the final ansible inventory file for the cluster installtion.
* run `prerequisites` playbook from openshift installer
  Does all pre requisites work.
* run `deploy_cluster` playboo from openshift installer
  Install and configure the whole cluster.
* POST_DEPLOY_TASKS
  Copy `kube-config` in place and runs some basic `oc` commands to check the cluster.
  It also add a admin user to the htpasswd files on the master servers.
* TEST_DEPLOYMENT
  runs an smoke test on the newly installed cluster
* PV_CREATION
  creates nfs directories and the corresponding persistent volumes.
* CICD
  installs a jenkins on the cluster and creates CI/CD workflow
  Configures HPA for `tasks-prod` project.
* MULTIPLE_CLIENTSA
  creates a multitanant setup with three projects. Two for each company and one for common other customers.

## Hosts in the Environment

This playbook script applies to the following host environment:

* bastion host:
  bastion.${GUID}.example.opentlc.com
  bastion.${GUID}.internal
* loadbalancer:
  loadbalancer.${GUID}.example.opentlc.com
  loadbalancer1.${GUID}.internal
* OCP master nodes:
  master{1..3}.${GUID}.example.opentlc.com
  master{1..3}.${GUID}.internal
* OCP infrastructure nodes:
  infranode{1..2}.${GUID}.example.opentlc.com
  infranode{1..2}.${GUID}.internal
* OCP worker nodes:
  node{1..4}.${GUID}.example.opentlc.com
  node{1..4}.${GUID}.internal

## Journal

### basic requirement

* Ability to authenticate at the master console
  Master console is accessable via https://loadbalancer.${GUID}.example.opentlc.com and user *admin* can login with password *r3dh4t1!*
* Registry has storage attached and working
  run following command to check
```
# oc get pv | grep -i bound
etcd-asb-volume                  10G        RWO            Retain           Bound       openshift-ansible-service-broker/etcd                                26m
logging-volume                   10Gi       RWO            Retain           Bound       logging/logging-es-0                                                 26m
metrics-volume                   10Gi       RWO            Retain           Bound       openshift-infra/metrics-cassandra-1                                  26m
prometheus-alertbuffer-volume    10Gi       RWO            Retain           Bound       openshift-metrics/prometheus-alertbuffer                             26m
prometheus-alertmanager-volume   10Gi       RWO            Retain           Bound       openshift-metrics/prometheus-alertmanager                            26m
prometheus-volume                10Gi       RWO            Retain           Bound       openshift-metrics/prometheus                                         26m
pv24                             5Gi        RWO            Recycle          Bound       smoke-test-nodejs/mongodb                                            14m
pv6                              5Gi        RWO            Recycle          Bound       cicd-dev/jenkins                                                     14m
registry-volume                  20Gi       RWX            Retain           Bound       default/registry-claim                                               26m
```
* Router is configured on each infranode
  run following command to check
```
# oc get pod -n default -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP              NODE
docker-registry-1-v2m7r    1/1       Running   0          28m       10.130.0.3      infranode1.a822.internal
registry-console-1-9g9kc   1/1       Running   0          27m       10.131.2.3      master1.a822.internal
router-1-f5g6d             1/1       Running   0          28m       192.199.0.30    infranode1.a822.internal
router-1-xkhwb             1/1       Running   0          28m       192.199.0.171   infranode2.a822.internal
```
* PVs of different types are available for users to consume
  run following command to check. The command shows a shriked list of pv's.
```
# oc get pv | tail -n +2 | sort -k2 -u
logging-volume                   10Gi       RWO            Retain           Bound       logging/logging-es-0                                                 34m
metrics-volume                   10Gi       RWO            Retain           Bound       openshift-infra/metrics-cassandra-1                                  34m
prometheus-volume                10Gi       RWO            Retain           Bound       openshift-metrics/prometheus                                         34m
prometheus-alertbuffer-volume    10Gi       RWO            Retain           Bound       openshift-metrics/prometheus-alertbuffer                             34m
prometheus-alertmanager-volume   10Gi       RWO            Retain           Bound       openshift-metrics/prometheus-alertmanager                            34m
pv26                             10Gi       RWX            Retain           Available                                                                        21m
etcd-asb-volume                  10G        RWO            Retain           Bound       openshift-ansible-service-broker/etcd                                34m
registry-volume                  20Gi       RWX            Retain           Bound       default/registry-claim                                               34m
pv10                             5Gi        RWO            Recycle          Available                                                                        21m
pv1                              5Gi        RWO            Recycle          Available                                                                        21m
pv6                              5Gi        RWO            Recycle          Bound       cicd-dev/jenkins                                                     21m
pv24                             5Gi        RWO            Recycle          Bound       smoke-test-nodejs/mongodb                                            21m
```
* Ability to deploy a simple app (nodejs-mongo-persistent)
  `ansible/roles/TEST_DEPLOYMENT/` does the work here.

### HA Requirements

* There are three masters working
* There are three etcd instances working
* There is a load balancer to access the masters called loadbalancer.$GUID.$DOMAIN
* There is a load balancer/DNS for both infranodes called \*.apps.$GUID.$DOMAIN
* There are at least two infranodes, labeled env=infra
  the requirements are implemented in the following roles
  `ansible/roles/CREATE_HOST_FILE`

### Environment Configuration

* NetworkPolicy is configured and working with projects isolated by default
  is activated via `os_sdn_network_plugin_name='redhat/openshift-ovs-networkpolicy'` configuration parameter in inventory.
* Aggregated logging is configured and working
* Metrics collection is configured and working
* Router and Registry Pods run on Infranodes
* Metrics and Logging components run on Infranodes
* Service Catalog, Template Service Broker, and Ansible Service Broker are all working
  is done in role `ansible/roles/CREATE_HOST_FILE` and corresponding configuration parameters in inventory.

### CICD Workflow

* Jenkins pod is running in a project called cicd-dev with a persistent volume
* Jenkins deploys openshift-tasks app
* Jenkins OpenShift plugin is used in the buildconfig to create a CICD workflow
* Use tasks-build as your project for building. Do promotion between projects tasks-dev, tasks-test, and tasks-prod as your project names.
* HPA called tasks-hpa is configured and working on production deployment of openshift-tasks in project tasks-prod.
  work is done by roles:
  `ansible/roles/CICD`

### Multitenancy

* Multiple Clients (customers) created
  * Clients will be named Alpha Corp and Beta Corp (client=alpha, client=beta), and a "client=common" for unspecified customers.
  * Alpha Corp will have two users, Amy and Andrew
  * Beta Corp will have two users, Brian and Betty
  * Common will be for all other users workloads
* Dedicated node for each Client
* The new project template is modified so that it includes a LimitRange
* A new user template is used to create a user object with the specific label value (optional)
* Alpha and Beta Corp users are confined to projects, and all new pods are deployed to customer dedicated nodes
  The following roles are responsible for the work:
  `ansible/roles/MULTIPLE_CLIENTS`

