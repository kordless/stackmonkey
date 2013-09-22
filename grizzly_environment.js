{
  "name": "grizzly",
  "description": "OpenStack Grizzly via BlueChip Install",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
  },
  "override_attributes": {
    "nova": {
      "networks": [
        {
          "label": "public",
          "bridge_dev": "${bridge_interface}",
          "ipv4_cidr": "${internal_network}",
          "bridge": "br100",
          "dns1": "8.8.4.4",
          "dns2": "8.8.8.8"
        }
      ]
    },
    "mysql": {
      "allow_remote_root": true,
      "root_network_acl": "%"
    },
    "osops_networks": {
      "nova": "${public_network}",
      "public": "${public_network}",
      "management": "${public_network}"
    }
  }
}
