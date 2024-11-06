# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.47.1"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.36.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "EKSAddon" = "ebs-csi"
    "Terraform" = "true"
  }
}
/*
data "aws_iam_policy" "awslm_consumption_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLicenseManagerConsumptionPolicy"
}

module "irsa-haproxy-ingress-controller-ee" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.33.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFHAProxyIngressControllerRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.awslm_consumption_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:haproxy-ingress-controller-ee-sa"]
}

resource "aws_eks_addon" "haproxy-ingress-controller-ee" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "haproxy-technologies_kubernetes-ingress-ee"
  addon_version            = "v1.30.0-eksbuild.0"
  service_account_role_arn = module.irsa-haproxy-ingress-controller-ee.iam_role_arn
  tags = {
    "EKSAddon" = "haproxy-ingress-ee"
    "Terraform" = "true"
  }
}
*/