# VPC resource
resource aws_vpc" "login-vpc"{
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    tag = {
        Name = "login_vpc"
    }
}
# Subnets for public & private
resource "aws_subnet" "login-fe-sn" {
    vpc_id = aws_vpc.login-vpc.id
    cidr_block = "10.0.1.0/25"
    availability_zone  = "us-east-1a"
    map_public_ip_on_launch = "true"
    tag = {
        Name = "login-frontend-subnet"
    }
}

resource "aws_subnet" "login-be-sb" {
    vpc_id = aws_vpc.login-vpc.id
    cidr_block = "10.0.2.0/25"
    availability_zone = "us-east-1b"
    map_public_on_launch_ip = "true"
    tag = {
        Name = "login-backend-subnet"
    }
}

resource "aws_subnet" "login-db-sn" {
    vpc_id = aws_vpc.login-vpc.id
    cidr_block = "10.0.3.0/25"
    availability_zone = "us-east-1c"
    map_public_ip_on_launch = "false"
    tag = {
        Name = "login-database-subnet"
    }
}
#AWS-INTERNETGATEWAY

resource "aws_internet_gateway" "login-IGW" {
    vpc_id = aws_vpc.login-vpc.id
    tag = {
        Name = "login-IGW"
    }
}
#AWS-ROUTETABLE

resource "aws_route_table" "login-public-rt" {
    vpc_id = aws_vpc.login-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_route_table.login-IGW.id
    } 
    tag = {
        Name = "login-public-routetable"
    }
}

resource "aws_route_table" "login-prv-rt" {
    vpc_id = aws_vpc.login-vpc.id
    tag = {
        Name = "login-private-routetable"
    }
}
#AWS-ROUTETABLE-ASSOCIATION

resource "aws_route_table_association" "login-web-assoc" {
    subnet_id = aws_subnet.login-fe-sn.id
    route_table_id = aws_route_table.login-public-rt.id
}

resource "aws_route_table_association" "login-app-assoc" {
    subnet_id = aws_subnet.login-be-sn.id
    route_table_id = aws_route_table.login-public-rt.id
}

resource "aws_route_table_association" "login-db-assoc" {
    subnet_id = aws_subnet.login-db-sn.id
    route_table_id = aws_route_table.login-prv-rt.id
}
# NACL RESOURCE
resource "aws_network_cal" "login_custom_nacl" {
    vpc_id = aws_vpc.login-vpc.id
     
    egress {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 65535
  }
    ingress {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 65535
  }
    tag = {
        Name = "login-custom-nacl"
    }

    }
# SECURITY-GROUPS
resource "aws_security_group" "login-frontend-sg" {
    name = "frontend-sg"
    description = "allow all frontend traffic"
    vpc_id = aws_vpc.login-vpc.id
    tag = {
        Name = "login-frontend-sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "login-fe-sg-ssh" {
    security_group_id = aws_security_group.login-frontend-sg.id

    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 22
    ip_protocol = "tcp"
    to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "login_fe_sg_http" {
  security_group_id = aws_security_group.login_frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "login_fe_sg_outbound" {
  security_group_id = aws_security_group.login_frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

# Security Group For Backend
resource "aws_security_group" "login_app_sg" {
  name        = "backend_sg"
  description = "Allow Backend Traffic"
  vpc_id      = aws_vpc.login-vpc.id

  tags = {
    Name = "backend_sg"
  }
}

# Backend SSH
resource "aws_vpc_security_group_ingress_rule" "login_app_sg_ssh" {
  security_group_id = aws_security_group.login_app_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# Backend HTTP
resource "aws_vpc_security_group_ingress_rule" "login_app_sg_http" {
  security_group_id = aws_security_group.login_app_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 8080
  ip_protocol = "tcp"
  to_port     = 8080
}

# Backend ALL - OutBound
resource "aws_vpc_security_group_egress_rule" "login_app_sg_outbound" {
  security_group_id = aws_security_group.login_app_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

# db SG
resource "aws_security_group" "login_db_sg" {
  name        = "database_sg"
  description = "Allow Database Traffic"
  vpc_id      = aws_vpc.login-vpc.id

  tags = {
    Name = "database_sg"
  }
}

# Database SSH
resource "aws_vpc_security_group_ingress_rule" "login_db_sg_ssh" {
  security_group_id = aws_security_group.login_db_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# Database POSTGRES
resource "aws_vpc_security_group_ingress_rule" "login_db_sg_postgres" {
  security_group_id = aws_security_group.login_db_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
}

# Database ALL - OutBound
resource "aws_vpc_security_group_egress_rule" "login_db_sg_outbound" {
  security_group_id = aws_security_group.login_db_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
