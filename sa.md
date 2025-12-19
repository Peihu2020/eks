Here's how to create the IAM role manually through the AWS Console:

## 🖥️ **Step-by-Step: Creating the IAM Role in AWS Console**

### **1. Navigate to IAM Console**
1. Go to the **AWS Management Console**
2. Search for and select **"IAM"** (Identity and Access Management)

### **2. Create a New IAM Role**
1. In the left sidebar, click **"Roles"**
2. Click the **"Create role"** button (blue button, top-right)

### **3. Select Trusted Entity Type**
1. Under **"Select trusted entity"**, choose **"Web identity"**
2. In the dropdown for **"Identity provider"**, select:
   - **Choose a provider**: `oidc.eks.ap-east-1.amazonaws.com/id/D9512A70A42160AF8D6E761B9E8E8299`
3. Under **"Audience"**, enter: `sts.amazonaws.com`
4. Click **"Next"**

### **4. Add Permissions (Attach Policies)**
1. On the **"Add permissions"** page, search for your policy:
   - In the search box, type: `AWSLoadBalancerControllerIAMPolicy`
   - **If it appears**: Check the box next to it
   - **If it doesn't appear**: Click **"Create policy"** (opens new tab), then:
     a. Click **"JSON"** tab
     b. Paste the policy content from [AWS documentation](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json)
     c. Click **"Next"**, add tags (optional), **"Next"** again
     d. Name it: `AWSLoadBalancerControllerIAMPolicy`
     e. Click **"Create policy"**
     f. Return to the role creation tab, refresh the policy list, and select your new policy
2. Click **"Next"**

### **5. Configure Role Details**
1. **Role name**: Enter `Manual-eks-goldbar-eks-01-aws-load-balancer-controller`
2. **Description**: `IAM role for AWS Load Balancer Controller on goldbar-eks-01`
3. Click **"Next"**

### **6. Review and Create**
1. Review all settings:
   - **Trusted entities**: Should show your OIDC provider
   - **Permissions policies**: Should show `AWSLoadBalancerControllerIAMPolicy`
2. Click **"Create role"**

### **7. Add the Condition to Trust Relationship (CRITICAL STEP)**
After creating the role, you must add the specific condition to limit which service account can use it:

1. Click on your newly created role name: `Manual-eks-goldbar-eks-01-aws-load-balancer-controller`
2. Go to the **"Trust relationships"** tab
3. Click **"Edit trust policy"**
4. **Replace** the entire JSON policy with your exact trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::114571653972:oidc-provider/oidc.eks.ap-east-1.amazonaws.com/id/D9512A70A42160AF8D6E761B9E8E8299"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.ap-east-1.amazonaws.com/id/D9512A70A42160AF8D6E761B9E8E8299:aud": "sts.amazonaws.com",
          "oidc.eks.ap-east-1.amazonaws.com/id/D9512A70A42160AF8D6E761B9E8E8299:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
```
5. Click **"Update policy"**

### **8. Get the Role ARN**
1. On the role's **"Summary"** page, find the **"Role ARN"**
2. Copy the full ARN (it will look like: `arn:aws:iam::114571653972:role/Manual-eks-goldbar-eks-01-aws-load-balancer-controller`)
3. **Save this ARN** for the next step

## 🔗 **Step 2: Link the Role to Kubernetes (Back to Terminal)**

After creating the role in the console, return to your terminal to annotate the Kubernetes service account:

```bash
# Use the ARN from Step 8
ROLE_ARN="arn:aws:iam::114571653972:role/Manual-eks-goldbar-eks-01-aws-load-balancer-controller"

# Annotate the service account (update if exists, create if not)
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=$ROLE_ARN \
  --overwrite

# If the service account doesn't exist, create it:
# kubectl create serviceaccount aws-load-balancer-controller -n kube-system
# kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system eks.amazonaws.com/role-arn=$ROLE_ARN

# Restart the controller pods
kubectl delete pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify pods restart
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -w
```

## ✅ **Visual Verification in Console**
After completing these steps, verify in the AWS Console:

| Location | What to Check | Expected Result |
| :--- | :--- | :--- |
| **IAM → Roles** | Role `Manual-eks-goldbar-eks-01-aws-load-balancer-controller` exists | ✓ Role listed |
| **Role → Permissions** | `AWSLoadBalancerControllerIAMPolicy` attached | ✓ Policy attached |
| **Role → Trust relationships** | JSON matches exactly your trust policy | ✓ Correct OIDC provider and condition |
| **EC2 → Load Balancers** | New Application Load Balancer appears | ✓ ALB created (after pods restart) |
