# ansible-borgbackup

Installs [borg backup](https://www.borgbackup.org) and set up a systemd service.

## System requirements

* Systemd (if you want to set up a service)

## What this role does

* Installs borg from the [borg GitHub repo](https://github.com/borgbackup/borg)
* Create passphrase files
* Template backup script
* Create systemd service
* Create systemd timer

## Parameters

| Parameter name                         | Type            | Mandatory?                                            | Default value             | Description                                                                                                                                          |
|----------------------------------------|-----------------|-------------------------------------------------------|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| borgbackup_version                     |                 | no                                                    | [empty] => latest version | Specifies the version of borg to be installed                                                                                                        |
| borgbackup_working_directory           | absolute path   | no, only if you specify repos with encryption enabled | `''`                      | Specifies the location where your passphrase files will be stored                                                                                    |
| borgbackup_repos                       | array of `repo` | no                                                    | `[]`                      | Specifies the repos for your backup                                                                                                                  |
| borgbackup_ignore_failing_repos        | boolean         | no                                                    | `false`                   | By default your ansible playbook will fail if a repo fails to be initialized. Setting this property to `True` will ignore and omit all failing repos |
| borgbackup_no_strict_host_key_checking | boolean         | no                                                    | `false`                   | You can disable ssh strict host key checking with setting this switch to `yes`                                                                       |
| borgbackup_backup_devices              | array of texts  | no                                                    | `[]`                      | You can specify any backup drives which will be mounted before beackup and unmounted after (i. e. you can use USB drives)                            |
| borgbackup_install_from_apt            | boolean         | no                                                    | `false`                   | You can install the package `borgbackup` from `apt` if you wish                                                                                      |
| borgbackup_install_from_pip            | boolean         | no                                                    | `false`                   | You can install the package `borgbackup` from `pip` if you wish                                                                                      |
| borgbackup_linuxold                    | boolean         | no                                                    | `false`                   | Install `linuxold64` version for older linux versions (only if you don't install from `apt` and `pip`)                                               |

### Definition `repo`

| Parameter name        | Type               | Mandatory? | Default value | Description                                                                                                            |
|-----------------------|--------------------|------------|---------------|------------------------------------------------------------------------------------------------------------------------|
| repo_path             | absolute path      | yes        | [empty]       | Specifies the location of your repo. Also, ssh repos are supported. Make sure you have permissions to connect via ssh. |
| encryption_mode       | enum               | yes        | [empty]       | Specifies the encryption mode borg will use for this repo. Allowed: `repokey`, `repokey-blake2`                        |
| encryption_passphrase | text               | yes        | [empty]       | Your secret passphrase for your encrypted repo                                                                         |
| passphrase_filename   | file_name          | yes        | [empty]       | Filename of your passphrase file stored in `borgbackup_working_directory`                                              |
| archives              | array of `archive` | yes        | []            | The defined archives which will be stored in this repo                                                                 |
| prune                 | `prune` object     | no         | {}            | Containing your prune settings for this repo (recommended!)                                                            |
| disable_repo          | boolean            | no         | no            | You can disable a repo with this switch                                                                                |

### Definition `archive`

| Parameter name   | Type                    | Mandatory? | Default value | Description                                                                                                             |
|------------------|-------------------------|------------|---------------|-------------------------------------------------------------------------------------------------------------------------|
| name             | text                    | yes        | [empty]       | Specified the name of your archive                                                                                      |
| compression_mode | enum                    | no         | [empty]       | Specified the compression mode and level. Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| paths            | array of absolute paths | yes        | [empty]       | Specifies the paths which will be selected for backup into your archive. Specify at least one                           |
| exclude          | array of `exclude`      | no         | [empty]       | Specifies the exclude configuration for your archive.                                                                   |

### Definition `prune`

| Parameter name  | Type    | Mandatory? | Default value             | Description                                                                   |
|-----------------|---------|------------|---------------------------|-------------------------------------------------------------------------------|
| keep_within     | text    | no         | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_daily      | integer | no         | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_weekly     | integer | no         | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_monthly    | integer | no         | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |

### Definition `exclude`

| Parameter name | Type             | Mandatory? | Default value | Description                                                                                                                                     |
|----------------|------------------|------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| patterns       | array of strings | no         | [empty]       | Specifies the patterns which will be excluded from your archive. Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/create.html) |

## Usage

### Add to `requirements.yml`

```yaml
- name: setup-borgbackup
  src: https://github.com/borisskert/ansible-borgbackup.git
  scm: git
```

### Minimal `playbook.yml`

```yaml
- hosts: test_machine
  become: yes

  roles:
    - setup-borgbackup
```

### Typical `playbook.yml`

```yaml
- hosts: test_machine
  become: yes

  roles:
    - role: setup-borgbackup
      borgbackup_version: 1.4.0
      borgbackup_install_from_apt: false
      borgbackup_install_from_pip: false
      borgbackup_linuxold: false
      borgbackup_working_directory: /srv/borgbackup
      borgbackup_backup_devices:
        - /dev/my_drive
        - /dev/my_other_drive
      borgbackup_repos:
        - repo_path: /mnt/borgbackups/etc-backups
          encryption_mode: repokey
          encryption_passphrase: "thi5 is-mY_p@5sphr4s3 for /etc"
          passphrase_filename: etc_passphrase.txt
          prune:
            keep_within: 1d
            keep_daily: 7
            keep_weekly: 4
            keep_monthly: 12
          archives:
            - name: etc-archive
              compression_mode: lzma,4
              paths:
                - /etc
        - repo_path: /mnt/borgbackups/home-and-root-backups
          encryption_mode: repokey-blake2
          encryption_passphrase: "thi5 is-mY_p@5sphr4s3 for /home and /root"
          passphrase_filename: home_root_passphrase.txt
          prune:
            keep_daily: 7
          archives:
            - name: home-archive
              compression_mode: none
              paths:
                - /home
            - name: root-archive
              compression_mode: none
              paths:
                - /root
        - repo_path: /mnt/borgbackups/opt-backups
          prune:
            keep_weekly: 4
            keep_monthly: 12
          archives:
            - name: opt-archive
              compression_mode: none
              paths:
                - /opt
        - repo_path: ssh://my_ssh_user@remote_server.org//home/my_remote_path
          encryption_mode: repokey
          encryption_passphrase: "thi5 is-mY_p@5sphr4s3"
          passphrase_filename: remote_backup_passphrase.txt
          archives:
            - name: my-remote-archive
              compression_mode: lzma,9
              paths:
                - /etc
                - /home
                - /srv
                - /root
              exclude:
                patterns:
                  - '*.tmp'
                  - '*.log'
                  - '*.swp'
                  - '*.cache'
        - repo_path: ssh://disabled_user@disabled_server//borgbackup-test
          disable_repo: yes
          archives:
            - name: my-disabled-archive
              compression_mode: lzma,9
              paths:
                - /etc
                - /home
                - /srv
                - /root
              exclude:
                patterns:
                  - '*.tmp'
                  - '*.log'
                  - '*.swp'
                  - '*.cache'
```

## Testing

Requirements:

* [Vagrant](https://www.vagrantup.com/)
* [libvirt](https://libvirt.org/)
* [Ansible](https://docs.ansible.com/)
* [Molecule](https://molecule.readthedocs.io/en/latest/index.html)
* [yamllint](https://yamllint.readthedocs.io/en/stable/#)
* [ansible-lint](https://docs.ansible.com/ansible-lint/)
* [Docker](https://docs.docker.com/)

### Run within docker

```shell script
molecule test
```

### Run within Vagrant

```shell script
 molecule test --scenario-name vagrant --parallel
```

I recommend to use [pyenv](https://github.com/pyenv/pyenv) for local testing. Within the GitHub Actions pipeline I
use [my own molecule action](https://github.com/borisskert/molecule-action).
