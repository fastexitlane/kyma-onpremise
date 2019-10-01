common
=========

This role installs basic packages we need on all hosts of our infrastructure and configures the general environment (like http proxy).
Especially, it disables SELinux and `firewalld`

Requirements
------------

* We don't have any specific requirements except SSH access.
* Only for CentOS 7.

Role Variables
--------------

None.

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers
      roles:
         - role: common
