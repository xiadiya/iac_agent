Here's the Terraform code based on the provided architecture diagram and specifications:

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "main-subnet"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security group for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "default" {
  engine               = "postgresql"
  engine_version       = "17.0"
  instance_class       = "db.m5.xlarge"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "mydb"
  username             = "dbuser"
  password             = "dbpassword"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az             = false
  backup_retention_period = 1
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.main.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_launch_template" "ec2_template" {
  name_prefix   = "ec2-template"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI ID
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EC2 Instance"
    }
  }
}

resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

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

resource "aws_iam_role_policy" "rds_access" {
  name = "rds_access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = aws_db_instance.default.arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}
```

This Terraform code creates the infrastructure based on the provided architecture diagram and specifications. It includes:

1. A VPC with one subnet
2. Security groups for RDS and EC2 instances
3. An RDS PostgreSQL instance
4. An EC2 launch template and Auto Scaling Group
5. IAM role and policy for EC2 instances to access RDS

Note that you may need to adjust some values (like AMI ID) based on your specific requirements and region. Also, remember to handle sensitive information like database passwords securely in a production environment.