# Ocp Advanced Deployment Assignment Lab

Use this repository to install a acp advanced deployment assignment lab on an Homework Lab from labs.opentlc.com

## How to run

* git clone https://github.com/cmeissner/ocp_advanced_deployment.git
* cd ocp_advanced_deployment
* ansible-playbook -f 30 ansible/install_lab.yaml | tee -a /root/install_lab.log
* see into log file under ```/root/install_lab.log``` to get detailed information of all steps
* use ```oc``` and ```ocp web console``` to check installed stuff

To quarantee that the installation runs complete you may want to start the ```ansible-playbook``` command inside of ```screen``` or ```tmux```. Please refer documentation of these tools to know how to use it.

Bye
