# EKS Terraform 端到端部署项目

用 Terraform 在 AWS 上从零搭建一套完整的云原生基础设施:VPC → EKS 集群 → Node Group → 可观测性栈(kube-prometheus-stack)→ 自定义 Prometheus Exporter,全部代码化、可重复创建。

## 架构概览

```
VPC (自定义 module)
  └─ EKS Cluster
       ├─ Node Group (t3.small, 1~2 节点, 自动扩缩容)
       ├─ IAM Access Entries (集群访问权限管理,替代旧版 aws-auth ConfigMap)
       ├─ kube-prometheus-stack (Helm 部署, 含 Prometheus + Grafana)
       └─ 自定义 Python Exporter (Deployment + Service, LoadBalancer 暴露)

State 管理:S3 backend (remote state)
```

## 目录结构

```
.
├── eks.tf                  # EKS 集群定义 + provider 配置(aws/kubernetes/helm)
├── node.tf                 # Node Group + Node IAM Role/Policy
├── access.tf                # EKS Access Entry(集群访问权限绑定)
├── exporter.tf              # 自定义 Prometheus Exporter 的 K8s Deployment
├── service.tf                # Exporter 的 K8s Service(LoadBalancer)
├── helm.tf                  # kube-prometheus-stack Helm Release
├── state_backend.tf          # S3 remote state backend 配置
├── variable.tf                # 变量声明
├── terraform.tfvars          # 变量取值(VPC CIDR、子网)
├── modules/vpc/              # VPC 自定义模块(network/security_group/output等)
├── kubernetes/                # K8s 相关补充清单
└── post_destroy_check.sh      # 销毁后资源核对脚本(见下文)
```

## 前置依赖

- Terraform >= 1.x(provider 锁定:`hashicorp/aws ~> 6.0`、`hashicorp/kubernetes ~> 2.0`、`hashicorp/helm ~> 2.0`)
- AWS CLI,已配置好具备足够权限的 IAM 用户
- kubectl / helm(本地验证部署用)
- 一个已存在的 S3 bucket,用于存放 remote state(见下文"State 管理")

## 快速开始

```bash
# 0. 创建本地 terraform.tfvars(该文件不提交到 git,需自行创建)
cat > terraform.tfvars << EOF
vpc_cidr_block = "10.0.0.0/16"
subnet         = ["10.0.1.0/24", "10.0.2.0/24"]
gfpassword     = "你自己设定的Grafana密码"
EOF

# 1. 初始化(会自动读取 state_backend.tf 里的 S3 backend 配置)
terraform init

# 2. 查看变更计划
terraform plan

# 3. 部署(创建 VPC + EKS + Node Group + 可观测性栈 + Exporter)
terraform apply

# 4. 配置本地 kubectl 连接新集群
aws eks update-kubeconfig --region ap-southeast-1 --name <集群名>

# 5. 验证节点就绪
kubectl get nodes

# 6. 验证 Pod 运行状态
kubectl get pods -A
```

## State 管理

本项目使用 **S3 backend** 存储 Terraform state,配置见 `state_backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "elden-state-bucket"
    key    = "remote-state-lab/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
```

> **注意**:这个 S3 bucket 需要提前独立创建好(建议用一个单独的、本地 state 管理的最小化 bootstrap 项目创建,不要让它管理自己的 state,避免循环依赖)。

## 可观测性

- **kube-prometheus-stack**(通过 `helm_release` 部署):包含 Prometheus + Grafana + Alertmanager,命名空间 `monitoring`
- **自定义 Exporter**:Python 编写,暴露 `/metrics`(端口 8000)供 Prometheus 抓取,`/health` 端点(端口 5000)做存活探针

获取 Grafana 访问地址:
```bash
kubectl get svc -n monitoring kps-grafana
```
拿到 `EXTERNAL-IP` 后浏览器访问即可,默认用户名 `admin`。

## 权限设计

- **Node IAM Role**:挂载 `AmazonEKSWorkerNodePolicy`、`AmazonEKS_CNI_Policy`、`AmazonEC2ContainerRegistryReadOnly` 三个最小必需策略
- **EKS Access Entry**:使用新版 Access Entry API(取代旧版 `aws-auth` ConfigMap 方式)管理集群访问权限,当前绑定的 IAM 用户拥有 `AmazonEKSClusterAdminPolicy`

## 安全设计

- Grafana 管理员密码通过 `var.gfpassword`(`sensitive = true`)传入,不硬编码在代码里。实际取值放在本地 `terraform.tfvars`,该文件已加入 `.gitignore`,不会被提交到版本控制。运行前需自行创建/编辑 `terraform.tfvars` 并设置:
  ```hcl
  gfpassword = "你的密码"
  ```

## 已知待办

- Node Group 当前为单一 `t3.small` 机型、无多可用区显式拆分,后续可扩展为多 AZ、多机型的 Node Group 或 Karpenter 自动扩缩容
- Grafana 密码目前仍以明文形式存在本地 `.tfvars` 中,生产环境可进一步升级为 AWS Secrets Manager 或 SSM Parameter Store 集中管理

## 资源清理

```bash
terraform destroy
```

销毁后建议运行核对脚本,确认没有残留计费资源(EC2、EBS、EIP、NAT Gateway、EKS 集群等):

```bash
./post_destroy_check.sh
```

## 技术栈

Terraform · AWS (EKS / VPC / IAM / S3) · Kubernetes · Helm · Prometheus · Grafana · Python
