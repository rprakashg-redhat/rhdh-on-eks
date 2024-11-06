module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "20.28.0"

    cluster_name = var.name
    cluster_version = var.k8sversion
    
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    cluster_endpoint_public_access = true

    # EKS Addons
    cluster_addons = {
        coredns                 = {}
        eks-pod-identity-agent  = {}
        kube-proxy              = {}
        vpc-cni                 = {}
    }

    enable_cluster_creator_admin_permissions = true

    # This is to prevent from having issues provisioning Service Type Loadbalancer
    node_security_group_tags = {
        "kubernetes.io/cluster/${var.name}" = null
    }

    eks_managed_node_groups = {
        one = {
            name            = "node-group-1"
            ami_type        = "AL2_x86_64"
            instance_types  = ["m5.2xlarge"]

            min_size     = 3
            max_size     = 5
            desired_size = 3

            pre_bootstrap_user_data = <<-EOT
            echo 'foo bar'
            EOT
        }
     }
       
     tags = local.tags
}