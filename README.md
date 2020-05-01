# ansible-borgbackup

Installs [borg backup](https://www.borgbackup.org) and setup a systemd service.

## System requirements

* Systemd (if you want to setup a service)

## What this role does

* Installs borg from the [borg Github repo](https://github.com/borgbackup/borg)
* Create passphrase files
* Template backup script
* Create systemd service
* Create systemd timer

## Parameters

| Parameter name | Type  | Mandatory?  | Default value             | Description |
|----------------|-------|-------------|---------------------------|-------------|
| version        |       | no          | [empty] => latest version | Specifies the version of borg to be installed |
| private_working_directory | absolute path | no, only if you specify repos with encryption enabled | [empty] | Specifies the location where your passphrase files will be stored |
| repos                     | array of `repo` | no                                                    | []    | Specifies the repos for your backup                               |
| ignore_failing_repos      | boolean         | no                                                    | no    | By default your ansible playbook will fail if a repo fails to be initialized. Setting this property to `True` will ignore and omit all failing repos |
| no_strict_host_key_checking | boolean       | no                                                    | no    | You can disable ssh strict host key checking with setting this switch to `yes`                                                                       |
| backup_devices              | array of texts | no                                                   | []    | You can specify any backup drives which will be mounted before beackup and unmounted after (i. e. you can use USB drives)                            |
| install_from_apt            | boolean        | no                                                   | no    | You can install the package `borgbackup` from apt if you wish                                                                                        |

### Definition `repo`

| Parameter name | Type  | Mandatory?  | Default value             | Description |
|----------------|-------|-------------|---------------------------|-------------|
| repo_path      | absolute path | yes | [empty]                   | Specifies the location of your repo. Also, ssh repos are supported. Make sure you have permissions to connect via ssh. |
| encryption_mode | enum         | yes | [empty]                   | Specifies the encryption mode borg will use for this repo. Allowed: `repokey`, `repokey-blake2` |
| encryption_passphrase | text   | yes | [empty]                   | Your secret passphrase for your encrypted repo                                                  |
| passphrase_filename   | file_name | yes | [empty]                | Filename of your passphrase file stored in `private_working_directory`                          |
| archives              | array of `archive` | yes | []            | The defined archives which will be stored in this repo                                          |
| prune                 | `prune` object     | no  | {}            | Containing your prune settings for this repo (recommended!)                                     |
| disable_repo          | boolean            | no  | no            | You can disable a repo with this switch                                                         |

### Definition `archive`

| Parameter name | Type  | Mandatory?  | Default value             | Description |
|----------------|-------|-------------|---------------------------|-------------|
| name           | text  | yes         | [empty]                   | Specified the name of your archive |
| compression_mode | enum | no         | [empty]                   | Specified the compression mode and level. Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| paths            | array of absolute paths | yes | [empty]       | Specifies the paths which will be selected for backup into your archive. Specify at least one  |

### Definition `prune`

| Parameter name | Type  | Mandatory?  | Default value             | Description |
|----------------|-------|-------------|---------------------------|-------------|
| keep_within    | text  | no          | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_daily     | integer | no        | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_weekly    | integer | no        | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |
| keep_monthly   | integer | no        | [none]                    | Read the [docs](https://borgbackup.readthedocs.io/en/stable/usage/prune.html) |

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
      version: 1.1.11
      install_from_apt: no
      private_working_directory: /srv/borgbackup
      backup_devices:
        - /dev/my_drive
        - /dev/my_other_drive
      repos:
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
```
