# Proxmox-Setup
1. Normale Installation von Proxmox
2. Login, neuen Cluster erstellen (notwendig für proxmox-csi)
3. Neues LVM-Volume auf 2ter NVMe erstellen für VM's (local-vms)
4. Enterprise Repositories deaktivieren (arthur -> Updates -> Repositiories) und `pve-no-subscription` aktivieren.
5. "iGPU" als PCI-Express Passthroug Device für Iris XE konfigurieren (galaxy -> Resource Mappings -> Add)
6. Per SSH auf Host connecten (root@ip)
7. sudo installieren `apt get update && apt get install sudo`
8. Neuen PVE-User für Provisionierung mit OpenTofu erstellen:
    ```bash
    $ pveum user add terraform@pve
    $ pveum role add Terraform -privs "Mapping.Use, VM.Config.Network, Sys.PowerMgmt, VM.Snapshot, User.Modify, VM.Audit, Sys.Incoming, Permissions.Modify, VM.Snapshot.Rollback, Sys.Console, Pool.Allocate, VM.Backup, VM.PowerMgmt, Datastore.Audit, Sys.AccessNetwork, Mapping.Modify, Group.Allocate, Datastore.Allocate, SDN.Audit, Sys.Audit, VM.Allocate, VM.Console, Sys.Syslog, Pool.Audit, Realm.Allocate, Datastore.AllocateTemplate, SDN.Use, VM.Config.CDROM, VM.Config.Disk, VM.Config.Cloudinit, VM.Config.Memory, VM.Config.HWType, Datastore.AllocateSpace, VM.Clone, Realm.AllocateUser, Mapping.Audit, Sys.Modify, SDN.Allocate, VM.Migrate, VM.Config.Options, VM.GuestAgent.Unrestricted, VM.Config.CPU, VM.GuestAgent.Audit"
    $ pveum aclmod / -user terraform@pve -role Terraform
    $ pveum user token add terraform@pve provider --privsep=0
    ```
9. Token im `.env` file unter der Variable `TF_VAR_proxmox_api_token` speichern
10. Neuen Linux-User für terraform provider erstellen `useradd -m terraform`
11. sudoers privilegien konfigurieren `visud -f /etc/sudoers.d/terraform`:
    ```terraform ALL=(root) NOPASSWD: /sbin/pvesm
    terraform ALL=(root) NOPASSWD: /sbin/qm
    terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/*
    terraform ALL=(root) NOPASSWD: /usr/bin/whoami```
12. Lokal neuen SSH key generieren `ssh-keygen -t ed25519 -C "terraform@pve"` und Public-Key in `/home/terraform/.ssh/authorized_keys` hinterlegen.

# Talos Upgrade
1. Longhorn Manager updaten und via GUI Engine upgraden
1. Neue Image-URL generieren: https://factory.talos.dev/?target=cloud (nocloud, Extensions iscsi-tools, qemu-guest-agent, util-linux-tools, i915)
2. Alle CloudNativePG in Maintenance-Mode versetzen:
```
spec:
...
  nodeMaintenanceWindow:
    inProgress: true
...
```
3. Via GitOps deployen.
4. Node für Node mit `talosctl upgrade --prevent --image $IMAGE_FACTORY_URL -n $IP
5. Warten
