output "sample-vpc-id" {
  value = aws_vpc.sample-vpc.id
}

output "sample-subnet-public01-id" {
  value = aws_subnet.sample-subnet-public01.id
}


output "sample-subnet-public02-id" {
  value = aws_subnet.sample-subnet-public02.id
}

output "sample-subnet-private01-id" {
  value = aws_subnet.sample-subnet-private01.id
}

output "sample-subnet-private02-id" {
  value = aws_subnet.sample-subnet-private02.id
}

output "sample-sg-bation-id" {
  value = aws_security_group.sample-sg-bastion-terraform.id
}

output "sample-security-group-elb-id" {
  value = aws_security_group.sample-sg-elb-terraform.id
}

output "default-security-groups-id" {
  value = aws_default_security_group.default.id
}
