# OneChart Reference

One chart to rule them all

A generic Helm chart for your application deployments. Because no one can remember the Kubernetes yaml syntax.

## Getting Started

OneChart is a generic Helm Chart for web applications. The idea is that most Kubernetes manifest look alike, only very few parts actually change.

You can also template and install onechart from an OCI repository as follows:

Check the generated Kubernetes yaml:

```bash
helm template my-release oci://ghcr.io/opsta/onechart --version 0.77.0 \
  --set image.repository=nginx \
  --set image.tag=1.19.3
```

Deploy with Helm:

```bash
helm install my-release oci://ghcr.io/opsta/onechart --version 0.77.0 \
  --set image.repository=nginx \
  --set image.tag=1.19.3
```

The example below deploys your application image, sets environment variables and configures the Kubernetes Ingress domain name:

```bash
helm template my-release oci://ghcr.io/opsta/onechart --version 0.77.0 -f values.yaml

# values.yaml
image:
  repository: my-app
  tag: fd803fc
vars:
  VAR_1: "value 1"
  VAR_2: "value 2"
ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
  host: my-app.mycompany.com
```

## Deploying an Image

OneChart settings for deploying the Nginx image:

```
image:
  repository: nginx
  tag: 1.19.3
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: nginx
  tag: 1.19.3
EOF

helm template my-release onechart/onechart -f values.yaml
```

## Deploying a Private Image

OneChart settings for deploying `my-web-app` image from Amazon ECR:

```
image:
  repository: aws_account_id.dkr.ecr.region.amazonaws.com/my-web-app
  tag: x.y.z

imagePullSecrets:
  - regcred
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: aws_account_id.dkr.ecr.region.amazonaws.com/my-web-app
  tag: x.y.z

imagePullSecrets:
  - regcred
EOF

helm template my-release onechart/onechart -f values.yaml
```

Image pull credentials must be set up in the cluster.

The `regcred` image pull credentials must be set up in the cluster. See how in [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).

## Environment Variables

OneChart settings for setting environment variables:

```
image:
  repository: nginx
  tag: 1.19.3

vars:
  VAR_1: 'value 1'
  VAR_2: 'value 2'
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: nginx
  tag: 1.19.3

vars:
  VAR_1: "value 1"
  VAR_2: "value 2"
EOF

helm template my-release onechart/onechart -f values.yaml
```

## Secrets

### Referencing Secret by Convention

Secrets demand special handling, and often they are stored, managed and configured in a workflow that is adjacent to application deployment.

Therefore, OneChart will not generate a Kubernetes `Secret` object by default, but it can reference one. Using the `secretEnabled: true` field, OneChart will look for a secret named exactly as your release.

```
image:
  repository: nginx
  tag: 1.19.3

secretEnabled: true
```

How the Kubernetes `Secret` object gets on the cluster, remains your task.

#### Creating Secrets

For testing purposes you can put the secret in your cluster with this command:

```
kubectl create secret generic my-release \
  --from-literal=SECRET1="my secret" \
  --from-literal=SECRET2="another secret"
```

Given that you called your release `my-release`.

### Referencing Secret by Name

You may use a secret with a custom name, by using the `secretName` field:

```
image:
  repository: nginx
  tag: 1.19.3

secretName: my-custom-secret
```

### Mounting Secrets as Files

You may use OneChart's `fileSecrets` feature to provide your application with long form secrets: SSH keys or json files that are typically used as service account keys on Google Cloud.

```
image:
  repository: nginx
  tag: 1.19.3

fileSecrets:
  - name: google-account-key
    path: /google-account-key
    secrets:
      key.json: supersecret
      another.json: |
        this
        is
        a
        multiline
        secret
```

- The above snippet will create a Kubernetes Secret object with two entries
- This secret is mounted to the `/google-account-key` and produce two files: `key.json` and `another.json`

An advanced version of mounting file secrets into pods, and doing it in a secure way is to use the `sealedFileSecrets` field. The behavior is identical to `fileSecrets`, it just uses a sealed secret as the content of the file:

```
image:
  repository: nginx
  tag: 1.19.3

sealedFileSecrets:
  - name: google-account-key
    path: /google-account-key
    filesToMount:
      - name: key.json
        source: AgA/7BnNhSkZAzbMqxMDidxK[...]
```

### Using Encrypted Secret Values

OneChart also has a secret workflow to keep secrets in git in an encrypted form. This requires that you have [Bitnami's Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) configured in your cluster.

You can ease the management of `SealedSecret` objects with OneChart's `sealedSecrets` field:

```
image:
  repository: nginx
  tag: 1.19.3

sealedSecrets:
  secret1: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
  secret2: ewogICJjcmVk...
```

You need to put already sealed values in the values.yaml file. To seal your secrets, use [Sealed Secret's raw mode](https://github.com/bitnami-labs/sealed-secrets#raw-mode-experimental).

Sealing string passwords:

```
echo -n mysupersecretstring | kubeseal  \
  --raw --scope cluster-wide \
  --controller-namespace=infrastructure \
  --from-file=/dev/stdin
```

Sealing entire files:

```
kubeseal \
  --raw --scope cluster-wide \
  --controller-namespace=infrastructure \
  --from-file=/home/laszlo/nats-testing-ca.crt
```

## Domain Names

OneChart generates a Kubernetes ingress resource for the Nginx ingress controller with the following settings:

```
image:
  repository: my-app
  tag: 1.0.0

ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
  host: chart-example.local
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: my-app
  tag: 1.0.0

ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
  host: my-app.mycompany.com
EOF

helm template my-app onechart/onechart -f values.yaml
```

The Nginx ingress controller must be set up in your cluster for this setting to work. For other ingress controllers, please use the matching annotation.

### HTTPS

To reference a TLS secret use the `tlsEnabled` field. The deployment will point to a secret named using the pattern `tls-<release-name>`.

```
cat << EOF > values.yaml
image:
  repository: my-app
  tag: 1.0.0

ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
  host: my-app.mycompany.com
  tlsEnabled: true
EOF

helm template my-app onechart/onechart -f values.yaml
```

### HTTPS - Let's Encrypt

If your cluster has Cert Manager running, you should add Cert Manager's annotation to have automated cert provisioning.

```
# values.yaml
image:
  repository: my-app
  tag: 1.0.0

ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
+   cert-manager.io/cluster-issuer: letsencrypt
  host: my-app.mycompany.com
  tlsEnabled: true
```

### Listening on multiple domains

```
cat << EOF > values.yaml
image:
  repository: my-app
  tag: 1.0.0

ingresses:
  - host: one.mycompany.com
    annotations:
      kubernetes.io/ingress.class: nginx
    tlsEnabled: true
  - host: two.mycompany.com
    annotations:
      kubernetes.io/ingress.class: nginx
    tlsEnabled: true
EOF

helm template my-app onechart/onechart -f values.yaml
```

## Volumes

OneChart settings for mounting volumes:

```
image:
  repository: nginx
  tag: 1.19.3

volumes:
  - name: data
    path: /data
    size: 10Gi
    storageClass: default
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: nginx
  tag: 1.19.3

volumes:
  - name: data
    path: /data
    size: 10Gi
    storageClass: default
EOF

helm template my-release onechart/onechart -f values.yaml
```

### Using Existing `PersistentVolumeClaims`

If for some reason you want to use an existing `PersistentVolumeClaim`, use the following syntax:

```
cat << EOF > values.yaml
image:
  repository: nginx
  tag: 1.19.3

volumes:
  - name: data
    path: /data
    existingClaim: my-static-claim
EOF

helm template my-release onechart/onechart -f values.yaml
```

### About Volumes

OneChart generates a `PersistentVolumeClaim` with this configuration and mounts it to the given path.

You have to know what `storageClass` is supported in your cluster.

- On Google Cloud, `standard` gets you disk.
- On Azure, `default` gets you a normal block storage.
- Use `do-block-storage` for Digital Ocean.

## Healthcheck

You can set a Kubernetes Readiness probe that determines whether your app is healthy and if it should receive traffic.

Enable it with:

```
probe:
  enabled: true
  path: "/"
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
probe:
  enabled: true
  path: "/"
EOF

helm template my-release onechart/onechart -f values.yaml
```

### Finetuning

You can further tune the frequency and thresholds of the probe with:

```
probe:
  enabled: false
  path: '/'
  settings:
    initialDelaySeconds: 0
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 3
    failureThreshold: 3
```

| Setting             | Description                                                                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| initialDelaySeconds | Number of seconds after the container has started before the probes is initiated.                                                                      |
| periodSeconds       | How often (in seconds) to perform the probe.                                                                                                           |
| successThreshold    | Minimum consecutive successes for the probe to be considered successful after having failed.                                                           |
| timeoutSeconds      | Number of seconds after which the probe times out.                                                                                                     |
| failureThreshold    | When a probe fails, Kubernetes will try this many times before giving up. If it gives up, the pod will be marked Unready and will not receive traffic. |

## High-Availability

OneChart makes your applications highly available as long as you set the replicas more than 1.

```
replicas: 2
```

By default, OneChart sets two more flags if the replica count is higher than one:

- PodDisruptionBudgets
- and pod anti affinity

These two flags make sure that your application pods are spread across nodes and never placed on the same one.

Also, in case of node maintenance, it makes sure that nodes are drained in an order that leaves at least one instance running from your application.

You can turn them off by setting the following values to `false`:

```
podDisruptionBudgetEnabled: true
spreadAcrossNodes: true
```

## Custom Command

OneChart settings for overriding the default command to run:

```
image:
  repository: debian
  tag: stable-slim

command: |
  while true; do date; sleep 2; done
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: debian
  tag: stable-slim

command: |
  while true; do date; sleep 2; done
EOF

helm template my-release onechart/onechart -f values.yaml
```

### Using bash

```
cat << EOF > values.yaml
image:
  repository: debian
  tag: stable-slim

command: |
  while true; do date; sleep 2; done
shell: "/bin/bash"
EOF

helm template my-release onechart/onechart -f values.yaml
```

### Running a Command in Alpine Linux

```
cat << EOF > values.yaml
image:
  repository: alpine
  tag: 3.12

command: |
  while true; do date; sleep 2; done
shell: "/bin/ash"
EOF

helm template my-release onechart/onechart -f values.yaml
```

## Security Context

For security reasons, if your application doesn't require root access and writing to the root file system, we recommend you to set `readOnlyRootFilesystem: true` and `runAsNonRoot: true`.

### Example of setting security context for containers

```
# values.yaml
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

### Example of setting security context for init containers

```
# values.yaml
initContainers:
- name: test
  image: test:test
  securityContext:
    readOnlyRootFilesystem: true
    runAsNonRoot: true
```

## Resources

```
cat << EOF > values.yaml
image:
  repository: debian
  tag: stable-slim

resources:
  limits:
    cpu: "2000m"
    memory: "2000Mi"
  requests:
    cpu: "200m"
    memory: "500Mi"
EOF

helm template my-release onechart/onechart -f values.yaml
```

## Cron Job

OneChart settings for deploying a cron job:

```
image:
  repository: debian
  tag: stable-slim

schedule: '0 1 0 0 0'
command: |
  echo "hello"
```

Check the Kubernetes manifest:

```
cat << EOF > values.yaml
image:
  repository: debian
  tag: stable-slim

schedule: "*/1 * * * *"
command: |
  echo "hello"
EOF

helm template my-release onechart/cron-job -f values.yaml
```

## Prometheus Monitoring Rules

This section shows how you can add a `PrometheusRule` to your app deployment.

This is a feature only supported by the [kube-stack-prometheus stack (formerly known as the Prometheus Operator)](https://github.com/prometheus-operator/kube-prometheus).

The following Prometheus rule alerts if a pod is crash-looping:

```
# values.yaml
image:
  repository: nginx
  tag: 1.19.3

prometheusRules:
  - name: KubePodCrashLooping
    message: "Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is restarting {{ printf \"%.2f\" $value }} times / 5 minutes."
    runBookURL: myrunbook.com
    expression: "rate(kube_pod_container_status_restarts_total{job=\"kube-state-metrics\", namespace=~\"{{ $targetNamespace }}\"}[15m]) * 60 * 5 > 0"
    for: 1h
    labels:
      severity: critical

helm template my-release onechart/onechart -f values.yaml
```

## Attaching a Sidecar

This section shows how you can add a sidecar container.

```
sidecar:
  repository: debian
  tag: stable-slim
```

Check the Kubernetes manifest:

```
helm template my-release onechart/onechart -f values.yaml
```

## Attaching a Sidecar For Debugging

This section shows how you can add a sidecar container with debug tools installed.

The debug sidecar container will have access to the same resources as your app container, so you don't have to inflate your app container with debug tools.

The following example adds a default debug container (a debian image) to your deployment, and you can verify that this container will have access to the defined volume.

```
sidecar:
  repository: debian
  tag: stable-slim
  shell: '/bin/bash'
  command: 'while true; do sleep 30; done;'

volumes:
  - name: data
    path: /data
    size: 1Gi
    storageClass: local-path
```

Check the Kubernetes manifest:

```
helm template my-release onechart/onechart -f values.yaml
```

## Supporting Any Kubernetes Field

Helm charts can be limiting. If OneChart did not template a particular Kubernetes yaml field, you have to reach for post-processing tools.

To bridge this gap in Helm, we provide the following mechanism.

### Example: Setting `hostNetwork`

The `hostNetwork` field is not templated in OneChart. Still, if you set the setting as seen below, OneChart will merge the hostNetwork field onto `.spec.template.spec` of the Deployment resource. Practically you can set any unimplemented field on the pod specification. Just add it to your values file under `podSpec`.

```
podSpec:
  hostNetwork: true
```

### Example: Overriding `imagePullPolicy`

The setting below will add or overwrite the Deployment resource's: `.spec.template.spec.containers[0]` field with any of the specified field. This way you can alter any implemented field in OneChart.

```
container:
  imagePullPolicy: Always
```
