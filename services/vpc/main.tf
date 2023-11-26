resource "aws_vpc" "sample-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sample-vpc"
  }
}

resource "aws_subnet" "sample-subnet-public01" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.0.0/20"
  tags = {
    Name = "sample-subnet-public01"
  }
}

resource "aws_subnet" "sample-subnet-private01" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.64.0/20"
  tags = {
    Name = "sample-subnet-private01"
  }
}

resource "aws_subnet" "sample-subnet-public02" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.16.0/20"
  tags = {
    Name = "sample-subnet-public02"
  }
}

resource "aws_subnet" "sample-subnet-private02" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.80.0/20"
  tags = {
    Name = "sample-subnet-private02"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sample-vpc.id

  tags = {
    Name = "sample-igw"
  }
}

resource "aws_eip" "elastic-ip-01" {
  domain = "vpc"
}


resource "aws_nat_gateway" "sample-ngw-01" {
  allocation_id = aws_eip.elastic-ip-01.id
  subnet_id     = aws_subnet.sample-subnet-public01.id

  tags = {
    Name = "sample-ngw-01"
  }
}

resource "aws_eip" "elastic-ip-02" {
  domain = "vpc"

}


resource "aws_nat_gateway" "sample-ngw-02" {
  allocation_id = aws_eip.elastic-ip-02.id
  subnet_id     = aws_subnet.sample-subnet-public02.id

  tags = {
    Name = "sample-ngw-02"
  }
}


resource "aws_route_table" "sample-rtb-public" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "sample-rtb-public"
  }
}

resource "aws_route_table_association" "relate-public-route-table1" {
  subnet_id      = aws_subnet.sample-subnet-public01.id
  route_table_id = aws_route_table.sample-rtb-public.id
}
resource "aws_route_table_association" "relate-public-route-table2" {
  subnet_id      = aws_subnet.sample-subnet-public02.id
  route_table_id = aws_route_table.sample-rtb-public.id
}


resource "aws_route_table" "sample-rtb-private01" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sample-ngw-01.id
  }

  tags = {
    Name = "sample-rtb-private01"
  }
}

resource "aws_route_table_association" "relate-private-route-table1" {
  subnet_id      = aws_subnet.sample-subnet-private01.id
  route_table_id = aws_route_table.sample-rtb-private01.id
}

resource "aws_route_table" "sample-rtb-private02" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sample-ngw-02.id
  }

  tags = {
    Name = "sample-rtb-private02"
  }
}

resource "aws_route_table_association" "relate-private-route-table2" {
  subnet_id      = aws_subnet.sample-subnet-private02.id
  route_table_id = aws_route_table.sample-rtb-private02.id
}


resource "aws_security_group" "sample-sg-bastion-terraform" {
  name        = "sample-sg-bastion-terraform"
  description = "for bastion server"
  vpc_id      = aws_vpc.sample-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sample-sg-elb-terraform" {
  name        = "sample-sg-elb-terraform"
  description = "for load balancer"
  vpc_id      = aws_vpc.sample-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.sample-vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
