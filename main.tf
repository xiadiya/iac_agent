Based on the architecture diagram and the provided configuration, here's the Terraform code to create the infrastructure:

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Main Subnet"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  engine                 = "postgres"
  engine_version         = "17.0"
  instance_class         = "db.m5.xlarge"
  multi_az               = false
  backup_retention_period = 1
  storage_encrypted      = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  subnet_id              = aws_subnet.main.id

  # Add other necessary configurations like allocated_storage, db_name, username, password, etc.
}

resource "aws_launch_template" "main" {
  name_prefix   = "ec2-launch-template"
  image_id      = "ami-xxxxxxxx"  # Replace with actual Amazon Linux 2 AMI ID for us-west-2
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Add other necessary configurations
}

resource "aws_autoscaling_group" "main" {
  name                = "ec2-asg"
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Add other necessary configurations
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2RDSAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_rds_access" {
  name = "EC2RDSAccessPolicy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2RDSAccessProfile"
  role = aws_iam_role.ec2_role.name
}
```

This Terraform code creates the infrastructure based on the provided architecture diagram and configuration. It includes:

1. A VPC with a subnet
2. Security groups for EC2 and RDS
3. An RDS instance
4. An EC2 launch template and Auto Scaling Group
5. IAM role and instance profile for EC2 instances to access RDS

Note that you may need to adjust some values (like the AMI ID) and add additional configurations as needed for your specific use case.