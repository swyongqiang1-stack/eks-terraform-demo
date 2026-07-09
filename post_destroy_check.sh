#!/bin/bash
# post_destroy_check.sh
# terraform destroy 之后跑一遍,确认 AWS 上没有残留资源在计费
# 用法: ./post_destroy_check.sh

set -uo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"
echo "=========================================="
echo "  Post-Destroy 资源核对  (region: $REGION)"
echo "=========================================="

echo ""
echo "--- [1/7] 打标签的资源(全局,含所有 region) ---"
aws resourcegroupstaggingapi get-resources \
  --query 'ResourceTagMappingList[*].[ResourceARN]' --output table

echo ""
echo "--- [2/7] 运行中的 EC2 实例 ---"
aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0],LaunchTime]' \
  --output table

echo ""
echo "--- [3/7] 未挂载的 EBS Volume(闲置计费) ---"
aws ec2 describe-volumes \
  --region "$REGION" \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' --output table

echo ""
echo "--- [4/7] 未关联的弹性 IP(闲置计费) ---"
aws ec2 describe-addresses \
  --region "$REGION" \
  --query 'Addresses[?AssociationId==`null`].[PublicIp,AllocationId]' --output table

echo ""
echo "--- [5/7] NAT Gateway(最容易漏删,按小时计费) ---"
aws ec2 describe-nat-gateways \
  --region "$REGION" \
  --filter "Name=state,Values=available,pending" \
  --query 'NatGateways[*].[NatGatewayId,State,VpcId]' --output table

echo ""
echo "--- [6/7] EKS 集群 ---"
CLUSTERS=$(aws eks list-clusters --region "$REGION" --query 'clusters' --output text)
if [ -z "$CLUSTERS" ]; then
  echo "  (无集群,干净)"
else
  echo "  发现残留集群: $CLUSTERS"
  for c in $CLUSTERS; do
    aws eks describe-cluster --region "$REGION" --name "$c" --query 'cluster.status' --output text
    aws eks list-nodegroups --region "$REGION" --cluster-name "$c" --output table
  done
fi

echo ""
echo "--- [7/7] 本月账单(按服务分组) ---"
START=$(date -u +%Y-%m-01)
END=$(date -u -d "+1 month" +%Y-%m-01 2>/dev/null || date -u -v+1m +%Y-%m-01)
aws ce get-cost-and-usage \
  --time-period Start="$START",End="$END" \
  --granularity MONTHLY --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[*].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' --output table

echo ""
echo "=========================================="
echo "  核对完成。逐项检查上面 7 项是否都为空 /"
echo "  账单是否只有接近 0 的历史费用。"
echo "  若发现残留,先手动定位再删除,不要"
echo "  盲目 terraform destroy 第二次。"
echo "=========================================="