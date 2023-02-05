# -*- mode: python -*-

# Copyright: (c) Intel Technology Poland 2023 by Milosz Linkiewicz (milosz.linkiewicz@intel.com)
# Copyright: Cloud Native Data Services Poland

from __future__ import absolute_import, division, print_function
__metaclass__ = type


DOCUMENTATION = r'''
---
module: add_inventory
short_description: Add dynamic inventory to ansible-playbook in-memory inventory. Mimics inventory plugin.
description:
- Uses inventory plugin workflow same as in add_inventory.
- Loads and parses dynamic inventory from provided path.
- This module is also supported for Windows targets.
version_added: "0.5"
options:
  path:
    description:
    - Full path to inventory file on controller machine.
    type: str
    required: true
    aliases: [ host, definitions, load ]
extends_documentation_fragment:
  - action_common_attributes
  - action_common_attributes.conn
  - action_common_attributes.flow
  - action_core
attributes:
    action:
        support: full
    core:
      details: While parts of this action are implemented in core, other parts are still available as normal plugins and can be partially overridden
      support: partial
    become:
      support: none
    bypass_host_loop:
        support: full
    bypass_task_loop:
        support: none
    connection:
        support: none
    delegation:
        support: none
    diff_mode:
        support: none
    platform:
        platforms: all
notes from module.add_host:
- The alias C(host) of the parameter C(name) is only available on Ansible 2.4 and newer.
- Since Ansible 2.4, the C(inventory_dir) variable is now set to C(None) instead of the 'global inventory source',
  because you can now have multiple sources.  An example was added that shows how to partially restore the previous behaviour.
- Though this module does not change the remote host, we do provide 'changed' status as it can be useful for those trying to track inventory changes.
- The hosts added will not bypass the C(--limit) from the command line, so both of those need to be in agreement to make them available as play targets.
seealso:
- plugin: inventory.intel.add_inventory
- module: add_host
- module: group_by
author:
- Cloud Native Data Services Poland
- Milosz Linkiewicz (milosz.linkiewicz@intel.com)
'''

EXAMPLES = r'''
- name: Add grouped batch of hosts from dynamic inventory file.
  intel.cloud.add_inventory:
    path: '{{ full_inventory_path }}'
'''
