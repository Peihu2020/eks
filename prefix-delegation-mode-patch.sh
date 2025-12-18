# 1. enable prefix delegation mode
kubectl patch daemonset aws-node -n kube-system --type='strategic' --patch='
spec:
  template:
    spec:
      containers:
      - name: aws-node
        env:
        - name: ENABLE_PREFIX_DELEGATION
          value: "true"
        - name: WARM_PREFIX_TARGET
          value: "1"
'

# 2. restart VPC-CNI Pods
kubectl rollout restart daemonset aws-node -n kube-system

# 3. wait for restart
kubectl rollout status daemonset aws-node -n kube-system --timeout=300s
