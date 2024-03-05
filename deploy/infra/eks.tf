module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "19.21.0"

    cluster_name = var.name
    cluster_version = var.k8sversion
    
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    cluster_endpoint_public_access = true

    eks_managed_node_group_defaults = {
        ami_type = "AL2_x86_64"

        attach_cluster_primary_security_group = true

        # Disabling and using externally provided security groups
        create_security_group = false
    }

    # This is to prevent from having issues provisioning Service Type Loadbalancer
    node_security_group_tags = {
        "kubernetes.io/cluster/${var.name}" = null
    }

    eks_managed_node_groups = {
        one = {
            name = "node-group-1"

            instance_types = ["m5.2xlarge"]

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