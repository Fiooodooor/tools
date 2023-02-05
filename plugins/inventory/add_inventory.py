#!/usr/bin/python

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
    name: inventory_merger
    version_added: "2.4"
    short_description: Parses a 'host list' string
    description:
        - Parses a host list string as a comma separated values of hosts
        - This plugin only applies to inventory strings that are not paths and contain a comma.
'''

EXAMPLES = r'''
    # define 2 hosts in command line
    # ansible -i '10.10.2.6, 10.10.2.4' -m ping all
    # DNS resolvable names
    # ansible -i 'host1.example.com, host2' -m user -a 'name=me state=absent' all
    # just use localhost
    # ansible-playbook -i 'localhost,' play.yml -c local
'''

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.module_utils._text import to_bytes, to_native, to_text
from ansible.parsing.utils.addresses import parse_address
from ansible.plugins.inventory import BaseInventoryPlugin, Constructable, Cacheable


class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable):

    NAME = 'add_inventory'

    def __init__(self):
        super(InventoryModule, self).__init__()
        self._filename = None

    def verify_file(self, path):
        '''
        Input:
        - path: string with inventory source (this is usually a path, but is not required)

        Output
        - valid: bool (true/false) if this is possibly a valid file for this plugin to consume
        '''
        
        valid = False
        if super(InventoryModule, self).verify_file(path):
            if path.endswith(('intel.yaml', 'intel.yml', 'wsf.yaml', 'wsf.yml')):
                valid = True
        elif '{' in path and '}' in path:
            valid = True

        return valid

    def parse(self, inventory, loader, path, cache=True):
        '''
        Input:
        - inventory: inventory object with existing data and the methods to add hosts/groups/variables to inventory
        - loader: Ansibles DataLoader. The DataLoader can read files, auto load JSON/YAML and decrypt vaulted data, and cache read files.
        - path: string with inventory source (this is usually a path, but is not required)
        - cache: indicates whether the plugin should use or avoid caches (cache plugin and/or loader)
        '''

        super(InventoryModule, self).parse(inventory, loader, path, cache)
        self._filename = path

        config = self._read_config_data(path)

        self._logical_groups = config['logical_groups']
        self._tf_global = config['terraform']
        self._tf_instances = config['terraform']['instances']

         # if NOT using _read_config_data you should call set_options directly,
         # to process any defined configuration for this plugin,
         # if you don't define any options you can skip
         #self.set_options()

        for logical_group in self._logical_groups:
            try:
                group = self.inventory.add_group(logical_group)
            except AnsibleError as e:
                raise AnsibleParserError("Failed to add group %s: %s" % (logical_group, to_text(e)))

            for instance_host in self._tf_instances:
                try:
                    if logical_group not in instance_host:
                        continue
                    self.inventory.add_host(instance_host, group=group)
                    self.inventory.set_variable(instance_host, 'ansible_host', self._tf_instances[instance_host]['public_ip'])
                    for key in self._tf_instances[instance_host]:
                        self.display.vvv('Using var: [%s=%s]' % (key, self._tf_instances[instance_host][key]))
                        self.inventory.set_variable(instance_host, key, self._tf_instances[instance_host][key])

                    self.display.vvv('Using group (%s) in instance_host (%s)' % (group, instance_host))
                except Exception as e:
                    raise AnsibleParserError("Parsing error. " + str(e))

    def _parse_host(self, host_pattern):
        '''
        Each host key can be a pattern, try to process it and add variables as needed
        '''
        try:
            (hostnames, port) = self._expand_hostpattern(host_pattern)
        except TypeError:
            raise AnsibleParserError(
                f"Host pattern {host_pattern} must be a string. Enclose integers/floats in quotation marks."
            )
        return hostnames, port