# 1. create cluster based on cluster.yaml definition, need to wait for around 18 minutes
eksctl create cluster -f cluster.yaml

# 2. enable prefix delegation mode
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

# 3. restart VPC-CNI Pods
kubectl rollout restart daemonset aws-node -n kube-system

# 4. wait for restart
kubectl rollout status daemonset aws-node -n kube-system --timeout=300s

# 5. update addon to config vpc cni iam permission
eksctl update addon -f addon-config.yaml
