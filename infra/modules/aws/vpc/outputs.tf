output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" { value = [for k, s in aws_subnet.this : s.id if startswith(k, "public-")] }
output "app_subnet_ids" { value = [for k, s in aws_subnet.this : s.id if startswith(k, "app-")] }
output "data_subnet_ids" { value = [for k, s in aws_subnet.this : s.id if startswith(k, "data-")] }
output "s3_endpoint_id" { value = aws_vpc_endpoint.s3.id }
