---
apiVersion: __DS_API_VERSION__
kind: DaemonSet
metadata:
  name: cilium-pre-flight-check
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: cilium-pre-flight-check
      kubernetes.io/cluster-service: "true"
  template:
    metadata:
      labels:
        k8s-app: cilium-pre-flight-check
        kubernetes.io/cluster-service: "true"
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: "k8s-app"
                operator: In
                values:
                - cilium
            topologyKey: "kubernetes.io/hostname"
      initContainers:
        - name: clean-cilium-state
          image: docker.io/cilium/cilium:__CILIUM_INIT_VERSION__
          imagePullPolicy: IfNotPresent
          command: ["/bin/echo"]
          args:
          - "hello"
__CILIUM_RM_SVC_V2__
      containers:
        - image: docker.io/cilium/cilium:__CILIUM_VERSION__
          imagePullPolicy: Always
          name: cilium-pre-flight-check
          command: ["/bin/sh"]
          args:
          - -c
          - "cilium preflight fqdn-poller --tofqdns-pre-cache /var/run/cilium/dns-precache-upgrade.json && touch /tmp/ready; sleep 1h"
          livenessProbe:
            exec:
              command:
              - cat
              - /tmp/ready
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            exec:
              command:
              - cat
              - /tmp/ready
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
          - mountPath: /var/run/cilium
            name: cilium-run
      hostNetwork: true
      restartPolicy: Always
      tolerations:
        - effect: NoSchedule
          key: node.kubernetes.io/not-ready
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
        - effect: NoSchedule
          key: node.cloudprovider.kubernetes.io/uninitialized
          value: "true"
        - key: CriticalAddonsOnly
          operator: "Exists"
      volumes:
        # To keep state between restarts / upgrades
      - hostPath:
          path: /var/run/cilium
          type: DirectoryOrCreate
        name: cilium-run
      - hostPath:
          path: /sys/fs/bpf
          type: DirectoryOrCreate
        name: bpf-maps
