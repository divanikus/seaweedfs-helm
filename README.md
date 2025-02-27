# seaweedfs

![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.85](https://img.shields.io/badge/AppVersion-3.85-informational?style=flat-square)

SeaweedFS is a simple and highly scalable distributed file system.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Andrey P. | <richter.einfach@pm.me> |  |
| Juri Malinovski | <coil93@gmail.com> |  |

## Getting Started

### Clone the helm repo

```bash
git clone https://github.com/divanikus/seaweedfs-helm.git
```

### Install the helm chart

```bash
helm install seaweedfs seaweedfs-helm
```

### (Recommended) Provide custom `values-custom.yaml`

```bash
helm install -f values-custom.yaml seaweedfs seaweedfs-helm
```

## Differences compared with the official seaweedfs helm chart

* Cut a lot of unnecessary settings like redefining port numbers of the services to make values.yaml less verbose.
* Tried to be more consistent in all block of options for each module. It also boils down to have PVCs only, but with same options for each module. Disabling persistence will force emptyDir instead.
* Made AIO module (server) for really small setups like dev environments. You should be able to plug it in into a distributed setup too, if you really want.
* Replaced environment vars for settings with actual config files stored within secrets and configmaps. Should be much easier to say connect to a specific filer storage, supplying it's creds through secret.
* Made an ability to directly pass args to weed process within values.yaml. Should add lots of flexibility, though might be a little bit controversial. I'm a little confused if it is ok to do that.
* Made it possible to have nodeSets with different settings/args for volume servers. You can specify settings in the global block and override it in a nodeSet.
* [cross-cluster continuous synchronization](https://github.com/seaweedfs/seaweedfs/wiki/Filer-Active-Active-cross-cluster-continuous-synchronization) support.
* Bucket TTL policy support.

### Prerequisites
#### Database

leveldb is the default database, this supports multiple filer replicas that will [sync automatically](https://github.com/seaweedfs/seaweedfs/wiki/Filer-Store-Replication), with some [limitations](https://github.com/seaweedfs/seaweedfs/wiki/Filer-Store-Replication#limitation).

When the [limitations](https://github.com/seaweedfs/seaweedfs/wiki/Filer-Store-Replication#limitation) apply, or for a large number of filer replicas, an external datastore is recommended.

### Notes
On production k8s deployment you will want each pod to have a different host, especially the volume server and the masters, all pods (master/volume/filer) should have anti-affinity rules to disallow running multiple component pods on the same host.
If you still want to run multiple pods of the same component (master/volume/filer) on the same host, please set/update the corresponding affinity rule in values.yaml to an empty one:

```affinity: ""```

### S3 configuration

To enable an s3 endpoint for your filer with a default install add the following to your values.yaml:

```yaml
filer:
  s3:
    enabled: true
```

#### Enabling authentication to S3

To enable authentication for S3, you have two options:

- let the helm chart create an admin user as well as a read-only user and anonymous user
- provide your own s3 config.json file via an existing Kubernetes Secret

#### Use the default credentials for S3
```yaml
filer:
  s3:
    enabled: true
    auth:
      enabled: true
      existingConfigSecret: my-s3-secret
```

#### Create S3 buckets

You may specify buckets to be created during the install process.
You may optionally specify ttl policy for the bucket.

```yaml
s3:
  enabled: true
  createBuckets:
    - name: bucket-a
      ttl: 1d
    - name: bucket-b
```

### Volume configuration

#### nodeSets example
```yaml
volume:
  args:
    dataCenter: hetzner
    rack: rack1
  nodeSets:
  - name: node1
    persistence:
      enabled: true
      disks:
      - disk: hdd
        size: 10Gi
  - name: node2
    persistence:
      enabled: true
      disks:
      - disk: hdd
        size: 10Gi
  - name: node3
    persistence:
      enabled: true
      disks:
      - disk: hdd
        size: 10Gi
```

### Replication configuration

#### Cross-cluster active-passive syncronization
```yaml
filer:
  sync:
    enabled: true
    args:
    - -a seaweedfs-filer.seaweedfs.cluster1:8888
    - -b seaweedfs-filer.seaweedfs.cluster2:8888
    - -isActivePassive
```

### Enable [IAM gateway server](https://github.com/seaweedfs/seaweedfs/wiki/Amazon-IAM-API)
```yaml
iam:
  enabled: true
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonAnnotations | object | `{}` |  |
| commonLabels | object | `{}` |  |
| cosi.bucketClassName | string | `"seaweedfs"` |  |
| cosi.containerSecurityContext | object | `{}` |  |
| cosi.driverName | string | `"seaweedfs.objectstorage.k8s.io"` |  |
| cosi.enableAuth | bool | `false` |  |
| cosi.enabled | bool | `false` |  |
| cosi.endpoint | string | `""` |  |
| cosi.existingConfigSecret | string | `nil` |  |
| cosi.extraVolumeMounts | list | `[]` |  |
| cosi.extraVolumes | list | `[]` |  |
| cosi.image | string | `"ghcr.io/seaweedfs/seaweedfs-cosi-driver:v0.1.1"` |  |
| cosi.podSecurityContext | object | `{}` |  |
| cosi.region | string | `""` |  |
| cosi.sidecar.image | string | `"gcr.io/k8s-staging-sig-storage/objectstorage-sidecar/objectstorage-sidecar:v20230130-v0.1.0-24-gc0cf995"` |  |
| extraEnvVars | list | `[]` |  |
| filer.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"seaweedfs.name\" . }}\n          app.kubernetes.io/instance: {{ .Release.Name }}\n          app.kubernetes.io/component: filer\n      topologyKey: kubernetes.io/hostname"` |  |
| filer.args.defaultReplicaPlacement | string | `"000"` |  |
| filer.config | string | `"[leveldb2]\n# local on disk, mostly for simple single-machine setup, fairly scalable\n# faster than previous leveldb, recommended.\nenabled = true\ndir = \"/data\""` |  |
| filer.containerSecurityContext | object | `{}` |  |
| filer.enabled | bool | `false` |  |
| filer.extraEnvVars | list | `[]` |  |
| filer.extraVolumeMounts | list | `[]` |  |
| filer.extraVolumes | list | `[]` |  |
| filer.ingress.annotations | object | `{}` |  |
| filer.ingress.className | string | `""` |  |
| filer.ingress.enabled | bool | `false` |  |
| filer.ingress.host | string | `"seaweedfs.cluster.local"` |  |
| filer.ingress.pathType | string | `"ImplementationSpecific"` |  |
| filer.ingress.tls | list | `[]` |  |
| filer.initContainers | list | `[]` |  |
| filer.livenessProbe.enabled | bool | `true` |  |
| filer.livenessProbe.failureThreshold | int | `5` |  |
| filer.livenessProbe.initialDelaySeconds | int | `20` |  |
| filer.livenessProbe.periodSeconds | int | `30` |  |
| filer.livenessProbe.successThreshold | int | `1` |  |
| filer.livenessProbe.timeoutSeconds | int | `10` |  |
| filer.logs.logLevel | int | `1` |  |
| filer.logs.logToStdErr | bool | `true` |  |
| filer.logs.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| filer.logs.persistence.annotations | object | `{}` |  |
| filer.logs.persistence.enabled | bool | `false` |  |
| filer.logs.persistence.existingClaim | string | `""` |  |
| filer.logs.persistence.selector | object | `{}` |  |
| filer.logs.persistence.size | string | `"10Gi"` |  |
| filer.logs.persistence.storageClass | string | `""` |  |
| filer.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| filer.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| filer.persistence.annotations | object | `{}` |  |
| filer.persistence.enabled | bool | `true` |  |
| filer.persistence.existingClaim | string | `""` |  |
| filer.persistence.selector | object | `{}` |  |
| filer.persistence.size | string | `"10Gi"` |  |
| filer.persistence.storageClass | string | `""` |  |
| filer.podAnnotations | object | `{}` |  |
| filer.podLabels | object | `{}` |  |
| filer.podManagementPolicy | string | `"Parallel"` |  |
| filer.podSecurityContext | object | `{}` |  |
| filer.priorityClassName | string | `""` |  |
| filer.readinessProbe.enabled | bool | `true` |  |
| filer.readinessProbe.failureThreshold | int | `100` |  |
| filer.readinessProbe.initialDelaySeconds | int | `10` |  |
| filer.readinessProbe.periodSeconds | int | `15` |  |
| filer.readinessProbe.successThreshold | int | `1` |  |
| filer.readinessProbe.timeoutSeconds | int | `10` |  |
| filer.replicas | int | `1` |  |
| filer.resources.limits | object | `{}` |  |
| filer.resources.requests | object | `{}` |  |
| filer.s3.args.allowEmptyFolder | bool | `false` |  |
| filer.s3.auditLogConfig | object | `{}` |  |
| filer.s3.auth.config | string | `"identities:\n- name: anonymous\n  actions:\n  - Read\n- name: anvAdmin\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Admin\n  - Read\n  - Write\n- name: anvReadOnly\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Read"` |  |
| filer.s3.auth.enabled | bool | `true` |  |
| filer.s3.auth.existingConfigSecret | string | `""` |  |
| filer.s3.enabled | bool | `false` |  |
| filer.s3.ingress.annotations | object | `{}` |  |
| filer.s3.ingress.className | string | `""` |  |
| filer.s3.ingress.enabled | bool | `false` |  |
| filer.s3.ingress.host | string | `"seaweedfs.cluster.local"` |  |
| filer.s3.ingress.pathType | string | `"ImplementationSpecific"` |  |
| filer.s3.ingress.tls | list | `[]` |  |
| filer.s3.onlyHttps | bool | `false` |  |
| filer.serviceAccountName | string | `""` |  |
| filer.sidecars | list | `[]` |  |
| filer.sync.args | list | `[]` |  |
| filer.sync.enabled | bool | `false` |  |
| filer.sync.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| filer.sync.podLabels | object | `{}` |  |
| filer.sync.podSecurityContext | object | `{}` |  |
| filer.sync.resources.limits | object | `{}` |  |
| filer.sync.resources.requests | object | `{}` |  |
| filer.tolerations | list | `[]` |  |
| filer.updateStrategy.rollingUpdate | object | `{}` |  |
| filer.updateStrategy.type | string | `"RollingUpdate"` |  |
| fullnameOverride | string | `""` |  |
| iam.admin.password | string | `""` |  |
| iam.admin.username | string | `"admin"` |  |
| iam.affinity | object | `{}` |  |
| iam.containerSecurityContext | object | `{}` |  |
| iam.enabled | bool | `false` |  |
| iam.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| iam.podSecurityContext | object | `{}` |  |
| iam.replicas | int | `1` |  |
| iam.resources.limits | object | `{}` |  |
| iam.resources.requests | object | `{}` |  |
| iam.tolerations | object | `{}` |  |
| iam.updateStrategy.type | string | `"Recreate"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.repository | string | `"chrislusf/seaweedfs"` |  |
| image.tag | string | `""` |  |
| logLevel | int | `1` |  |
| master.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"seaweedfs.name\" . }}\n          app.kubernetes.io/instance: {{ .Release.Name }}\n          app.kubernetes.io/component: master\n      topologyKey: kubernetes.io/hostname"` |  |
| master.args."ip.bind" | string | `"0.0.0.0"` |  |
| master.args.defaultReplication | string | `"000"` |  |
| master.args.volumePreallocate | bool | `false` |  |
| master.args.volumeSizeLimitMB | int | `1000` |  |
| master.config | string | `"# Enter any extra configuration for master.toml here.\n# It may be a multi-line string.\n[master.volume_growth]\ncopy_1 = 7                # create 1 x 7 = 7 actual volumes\ncopy_2 = 6                # create 2 x 6 = 12 actual volumes\ncopy_3 = 3                # create 3 x 3 = 9 actual volumes\ncopy_other = 1            # create n x 1 = n actual volumes"` |  |
| master.containerSecurityContext | object | `{}` |  |
| master.enabled | bool | `false` |  |
| master.extraEnvVars | list | `[]` |  |
| master.extraVolumeMounts | list | `[]` |  |
| master.extraVolumes | list | `[]` |  |
| master.ingress.annotations | object | `{}` |  |
| master.ingress.className | string | `""` |  |
| master.ingress.enabled | bool | `false` |  |
| master.ingress.host | string | `"master.seaweedfs.local"` |  |
| master.ingress.pathType | string | `"ImplementationSpecific"` |  |
| master.ingress.tls | list | `[]` |  |
| master.initContainers | list | `[]` |  |
| master.livenessProbe.enabled | bool | `true` |  |
| master.livenessProbe.failureThreshold | int | `4` |  |
| master.livenessProbe.initialDelaySeconds | int | `20` |  |
| master.livenessProbe.periodSeconds | int | `30` |  |
| master.livenessProbe.successThreshold | int | `1` |  |
| master.livenessProbe.timeoutSeconds | int | `10` |  |
| master.logs.logLevel | int | `1` |  |
| master.logs.logToStdErr | bool | `true` |  |
| master.logs.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| master.logs.persistence.annotations | object | `{}` |  |
| master.logs.persistence.enabled | bool | `false` |  |
| master.logs.persistence.existingClaim | string | `""` |  |
| master.logs.persistence.selector | object | `{}` |  |
| master.logs.persistence.size | string | `"10Gi"` |  |
| master.logs.persistence.storageClass | string | `""` |  |
| master.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| master.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| master.persistence.annotations | object | `{}` |  |
| master.persistence.enabled | bool | `true` |  |
| master.persistence.existingClaim | string | `""` |  |
| master.persistence.selector | object | `{}` |  |
| master.persistence.size | string | `"1Gi"` |  |
| master.persistence.storageClass | string | `""` |  |
| master.podAnnotations | object | `{}` |  |
| master.podLabels | object | `{}` |  |
| master.podManagementPolicy | string | `"Parallel"` |  |
| master.podSecurityContext | object | `{}` |  |
| master.priorityClassName | string | `""` |  |
| master.readinessProbe.enabled | bool | `true` |  |
| master.readinessProbe.failureThreshold | int | `100` |  |
| master.readinessProbe.initialDelaySeconds | int | `10` |  |
| master.readinessProbe.periodSeconds | int | `45` |  |
| master.readinessProbe.successThreshold | int | `2` |  |
| master.readinessProbe.timeoutSeconds | int | `10` |  |
| master.replicas | int | `1` |  |
| master.resources.limits | object | `{}` |  |
| master.resources.requests | object | `{}` |  |
| master.serviceAccountName | string | `""` |  |
| master.sidecars | list | `[]` |  |
| master.tolerations | list | `[]` |  |
| master.updateStrategy.rollingUpdate | object | `{}` |  |
| master.updateStrategy.type | string | `"RollingUpdate"` |  |
| metrics.dashboards.enabled | bool | `false` |  |
| metrics.enabled | bool | `false` |  |
| metrics.serviceMonitor.enabled | bool | `false` |  |
| metrics.serviceMonitor.interval | string | `"30s"` |  |
| metrics.serviceMonitor.labels | object | `{}` |  |
| metrics.serviceMonitor.scrapeTimeout | string | `"5s"` |  |
| nameOverride | string | `""` |  |
| rbac.create | bool | `true` |  |
| restartPolicy | string | `"Always"` |  |
| s3.affinity | string | `""` |  |
| s3.args."ip.bind" | string | `"0.0.0.0"` |  |
| s3.args.allowEmptyFolder | bool | `false` |  |
| s3.auditLogConfig | object | `{}` |  |
| s3.auth.config | string | `"identities:\n- name: anonymous\n  actions:\n  - Read\n- name: anvAdmin\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Admin\n  - Read\n  - Write\n- name: anvReadOnly\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Read"` |  |
| s3.auth.enabled | bool | `true` |  |
| s3.auth.existingConfigSecret | string | `""` |  |
| s3.containerSecurityContext | object | `{}` |  |
| s3.enabled | bool | `false` |  |
| s3.extraEnvVars | list | `[]` |  |
| s3.extraVolumeMounts | list | `[]` |  |
| s3.extraVolumes | list | `[]` |  |
| s3.ingress.annotations | object | `{}` |  |
| s3.ingress.className | string | `""` |  |
| s3.ingress.enabled | bool | `false` |  |
| s3.ingress.host | string | `"seaweedfs.cluster.local"` |  |
| s3.ingress.pathType | string | `"ImplementationSpecific"` |  |
| s3.ingress.tls | list | `[]` |  |
| s3.initContainers | list | `[]` |  |
| s3.internalTrafficPolicy | string | `"Cluster"` |  |
| s3.livenessProbe.enabled | bool | `true` |  |
| s3.livenessProbe.failureThreshold | int | `20` |  |
| s3.livenessProbe.initialDelaySeconds | int | `20` |  |
| s3.livenessProbe.periodSeconds | int | `60` |  |
| s3.livenessProbe.successThreshold | int | `1` |  |
| s3.livenessProbe.timeoutSeconds | int | `10` |  |
| s3.logs.logLevel | int | `1` |  |
| s3.logs.logToStdErr | bool | `true` |  |
| s3.logs.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| s3.logs.persistence.annotations | object | `{}` |  |
| s3.logs.persistence.enabled | bool | `true` |  |
| s3.logs.persistence.existingClaim | string | `""` |  |
| s3.logs.persistence.selector | object | `{}` |  |
| s3.logs.persistence.size | string | `"10Gi"` |  |
| s3.logs.persistence.storageClass | string | `""` |  |
| s3.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| s3.onlyHttps | bool | `false` |  |
| s3.podAnnotations | object | `{}` |  |
| s3.podLabels | object | `{}` |  |
| s3.podSecurityContext | object | `{}` |  |
| s3.priorityClassName | string | `""` |  |
| s3.readinessProbe.enabled | bool | `true` |  |
| s3.readinessProbe.failureThreshold | int | `100` |  |
| s3.readinessProbe.initialDelaySeconds | int | `15` |  |
| s3.readinessProbe.periodSeconds | int | `15` |  |
| s3.readinessProbe.successThreshold | int | `1` |  |
| s3.readinessProbe.timeoutSeconds | int | `10` |  |
| s3.replicas | int | `1` |  |
| s3.resources.limits | object | `{}` |  |
| s3.resources.requests | object | `{}` |  |
| s3.serviceAccountName | string | `""` |  |
| s3.sidecars | list | `[]` |  |
| s3.tolerations | list | `[]` |  |
| s3.updateStrategy.type | string | `"Recreate"` |  |
| security.config.jwtSigning.filerRead | bool | `false` |  |
| security.config.jwtSigning.filerWrite | bool | `false` |  |
| security.config.jwtSigning.volumeRead | bool | `false` |  |
| security.config.jwtSigning.volumeWrite | bool | `true` |  |
| security.enabled | bool | `false` |  |
| security.tls.commonName | string | `"SeaweedFS CA"` |  |
| security.tls.duration | string | `"2160h"` |  |
| security.tls.enabled | bool | `true` |  |
| security.tls.externalCertificates.enabled | bool | `false` |  |
| security.tls.ipAddresses | list | `[]` |  |
| security.tls.keyAlgorithm | string | `"RSA"` |  |
| security.tls.keySize | int | `2048` |  |
| security.tls.renewBefore | string | `"360h"` |  |
| server.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"seaweedfs.name\" . }}\n          app.kubernetes.io/instance: {{ .Release.Name }}\n          app.kubernetes.io/component: server\n      topologyKey: kubernetes.io/hostname"` |  |
| server.args."ip.bind" | string | `"0.0.0.0"` |  |
| server.containerSecurityContext | object | `{}` |  |
| server.enabled | bool | `false` |  |
| server.extraEnvVars | list | `[]` |  |
| server.extraVolumeMounts | list | `[]` |  |
| server.extraVolumes | list | `[]` |  |
| server.filer.args | object | `{}` |  |
| server.filer.config | string | `"[leveldb2]\n# local on disk, mostly for simple single-machine setup, fairly scalable\n# faster than previous leveldb, recommended.\nenabled = true\ndir = \"/data/filer\""` |  |
| server.filer.enabled | bool | `true` |  |
| server.filer.ingress.annotations | object | `{}` |  |
| server.filer.ingress.className | string | `""` |  |
| server.filer.ingress.enabled | bool | `false` |  |
| server.filer.ingress.host | string | `"filer.seaweedfs.local"` |  |
| server.filer.ingress.pathType | string | `"ImplementationSpecific"` |  |
| server.filer.ingress.tls | list | `[]` |  |
| server.initContainers | list | `[]` |  |
| server.livenessProbe.enabled | bool | `true` |  |
| server.livenessProbe.failureThreshold | int | `4` |  |
| server.livenessProbe.initialDelaySeconds | int | `20` |  |
| server.livenessProbe.periodSeconds | int | `30` |  |
| server.livenessProbe.successThreshold | int | `1` |  |
| server.livenessProbe.timeoutSeconds | int | `10` |  |
| server.logs.logLevel | int | `1` |  |
| server.logs.logToStdErr | bool | `true` |  |
| server.logs.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| server.logs.persistence.annotations | object | `{}` |  |
| server.logs.persistence.enabled | bool | `false` |  |
| server.logs.persistence.existingClaim | string | `""` |  |
| server.logs.persistence.selector | object | `{}` |  |
| server.logs.persistence.size | string | `"10Gi"` |  |
| server.logs.persistence.storageClass | string | `""` |  |
| server.master.args.defaultReplication | string | `"000"` |  |
| server.master.args.volumePreallocate | bool | `false` |  |
| server.master.args.volumeSizeLimitMB | int | `1000` |  |
| server.master.config | string | `"# Enter any extra configuration for master.toml here.\n# It may be a multi-line string.\n[master.volume_growth]\ncopy_1 = 7                # create 1 x 7 = 7 actual volumes\ncopy_2 = 6                # create 2 x 6 = 12 actual volumes\ncopy_3 = 3                # create 3 x 3 = 9 actual volumes\ncopy_other = 1            # create n x 1 = n actual volumes"` |  |
| server.master.ingress.annotations | object | `{}` |  |
| server.master.ingress.className | string | `""` |  |
| server.master.ingress.enabled | bool | `false` |  |
| server.master.ingress.host | string | `"master.seaweedfs.local"` |  |
| server.master.ingress.pathType | string | `"ImplementationSpecific"` |  |
| server.master.ingress.tls | list | `[]` |  |
| server.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| server.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| server.persistence.annotations | object | `{}` |  |
| server.persistence.enabled | bool | `true` |  |
| server.persistence.existingClaim | string | `""` |  |
| server.persistence.selector | object | `{}` |  |
| server.persistence.size | string | `"20Gi"` |  |
| server.persistence.storageClass | string | `""` |  |
| server.podAnnotations | object | `{}` |  |
| server.podLabels | object | `{}` |  |
| server.podManagementPolicy | string | `"Parallel"` |  |
| server.podSecurityContext | object | `{}` |  |
| server.priorityClassName | string | `""` |  |
| server.readinessProbe.enabled | bool | `true` |  |
| server.readinessProbe.failureThreshold | int | `100` |  |
| server.readinessProbe.initialDelaySeconds | int | `10` |  |
| server.readinessProbe.periodSeconds | int | `45` |  |
| server.readinessProbe.successThreshold | int | `2` |  |
| server.readinessProbe.timeoutSeconds | int | `10` |  |
| server.replicas | int | `1` |  |
| server.resources.limits | object | `{}` |  |
| server.resources.requests | object | `{}` |  |
| server.s3.args.allowEmptyFolder | bool | `false` |  |
| server.s3.auditLogConfig | object | `{}` |  |
| server.s3.auth.config | string | `"identities:\n- name: anonymous\n  actions:\n  - Read\n- name: anvAdmin\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Admin\n  - Read\n  - Write\n- name: anvReadOnly\n  credentials:\n  - accessKey: \"\"\n    secretKey: \"\"\n  actions:\n  - Read"` |  |
| server.s3.auth.enabled | bool | `true` |  |
| server.s3.auth.existingConfigSecret | string | `""` |  |
| server.s3.enabled | bool | `true` |  |
| server.s3.ingress.annotations | object | `{}` |  |
| server.s3.ingress.className | string | `""` |  |
| server.s3.ingress.enabled | bool | `false` |  |
| server.s3.ingress.host | string | `"seaweedfs.cluster.local"` |  |
| server.s3.ingress.pathType | string | `"ImplementationSpecific"` |  |
| server.s3.ingress.tls | list | `[]` |  |
| server.s3.onlyHttps | bool | `false` |  |
| server.serviceAccountName | string | `""` |  |
| server.sidecars | list | `[]` |  |
| server.tolerations | list | `[]` |  |
| server.updateStrategy.rollingUpdate | object | `{}` |  |
| server.updateStrategy.type | string | `"RollingUpdate"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `"seaweedfs"` |  |
| volume.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"seaweedfs.name\" . }}\n          app.kubernetes.io/instance: {{ .Release.Name }}\n          app.kubernetes.io/component: volume\n      topologyKey: kubernetes.io/hostname"` |  |
| volume.args.dataCenter | string | `"dc1"` |  |
| volume.containerSecurityContext | object | `{}` |  |
| volume.enabled | bool | `false` |  |
| volume.extraEnvVars | list | `[]` |  |
| volume.extraVolumeMounts | list | `[]` |  |
| volume.extraVolumes | list | `[]` |  |
| volume.initContainers | list | `[]` |  |
| volume.livenessProbe.enabled | bool | `true` |  |
| volume.livenessProbe.failureThreshold | int | `4` |  |
| volume.livenessProbe.initialDelaySeconds | int | `20` |  |
| volume.livenessProbe.periodSeconds | int | `90` |  |
| volume.livenessProbe.successThreshold | int | `1` |  |
| volume.livenessProbe.timeoutSeconds | int | `10` |  |
| volume.logs.logLevel | int | `1` |  |
| volume.logs.logToStdErr | bool | `true` |  |
| volume.logs.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| volume.logs.persistence.annotations | object | `{}` |  |
| volume.logs.persistence.enabled | bool | `false` |  |
| volume.logs.persistence.existingClaim | string | `""` |  |
| volume.logs.persistence.selector | object | `{}` |  |
| volume.logs.persistence.size | string | `"10Gi"` |  |
| volume.logs.persistence.storageClass | string | `""` |  |
| volume.nodeSelector | string | `"kubernetes.io/arch: amd64"` |  |
| volume.nodeSets[0].args.rack | string | `"rack1"` |  |
| volume.nodeSets[0].name | string | `"hdd"` |  |
| volume.nodeSets[0].persistence.disks[0].accessModes[0] | string | `"ReadWriteOnce"` |  |
| volume.nodeSets[0].persistence.disks[0].disk | string | `"hdd"` |  |
| volume.nodeSets[0].persistence.disks[0].existingClaim | string | `""` |  |
| volume.nodeSets[0].persistence.disks[0].max | int | `0` |  |
| volume.nodeSets[0].persistence.disks[0].size | string | `"50Gi"` |  |
| volume.nodeSets[0].persistence.disks[0].storageClass | string | `""` |  |
| volume.nodeSets[0].persistence.enabled | bool | `false` |  |
| volume.nodeSets[0].persistence.idx | object | `{}` |  |
| volume.nodeSets[0].replicas | int | `1` |  |
| volume.podAnnotations | object | `{}` |  |
| volume.podLabels | object | `{}` |  |
| volume.podManagementPolicy | string | `"Parallel"` |  |
| volume.podSecurityContext | object | `{}` |  |
| volume.priorityClassName | string | `""` |  |
| volume.readinessProbe.enabled | bool | `true` |  |
| volume.readinessProbe.failureThreshold | int | `100` |  |
| volume.readinessProbe.initialDelaySeconds | int | `15` |  |
| volume.readinessProbe.periodSeconds | int | `15` |  |
| volume.readinessProbe.successThreshold | int | `1` |  |
| volume.readinessProbe.timeoutSeconds | int | `30` |  |
| volume.resources.limits | object | `{}` |  |
| volume.resources.requests | object | `{}` |  |
| volume.serviceAccountName | string | `""` |  |
| volume.sidecars | list | `[]` |  |
| volume.tolerations | list | `[]` |  |
| volume.updateStrategy.rollingUpdate | object | `{}` |  |
| volume.updateStrategy.type | string | `"RollingUpdate"` |  |

### Update README

The `README.md` for this chart is generated by [helm-docs](https://github.com/norwoodj/helm-docs).
To update the README, edit the `README.md.gotmpl` file and run the helm-docs command.
