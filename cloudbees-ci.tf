# Install Nginx Ingress
resource "helm_release" "nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"
}

# CasC for 5 Controllers
resource "kubernetes_config_map" "casc" {
  metadata {
    name      = "cjoc-casc-bundle"
    namespace = "cloudbees-core"
  }
  data = {
    "bundle.yaml" = <<EOF
removeStrategy:
  items: "none"
items:
  $(for i in {1..5}; do
    echo "  - kind: managedController"
    echo "    name: \"controller-$i\""
    echo "    configuration:"
    echo "      kubernetes:"
    echo "        memory: 4096"
    echo "        cpus: 2.0"
  done)
EOF
  }
}

# CloudBees Core Helm
resource "helm_release" "cbci" {
  name       = "cloudbees-core"
  repository = "https://charts.cloudbees.com/public/cloudbees"
  chart      = "cloudbees-core"
  namespace  = "cloudbees-core"
  create_namespace = true
  values = [
    <<-EOF
    OperationsCenter:
      CasC:
        Enabled: true
        ConfigMapName: "cjoc-casc-bundle"
    EOF
  ]
  depends_on = [module.eks]
}