# Wazuh Project Work 

* Working to build a new 4.12 wazuh cluster to meet FIM and SIEM needs for PCI complience.
* Work to create a new wazuh cluster and upgrading out of date agents to the new cluster. 

## Specific Use Case for Wazuh Upgrade Shell Script

* This was created because of a move from legacy opensearch/elastic/wazuh set up to 4.12 wazuh as primary FIM and SIEM
* This script was to enable the upgrade wazuh agents to 4.12 - and remove filebeats and other configs logging to legacy SIEM and FIM. 
    * And register with new wazuh cluster. 

### Requirements and Running Agent Upgrade Script
