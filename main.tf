Based on the provided architecture diagram and configuration details, here's the Terraform code to create the infrastructure:

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

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  engine               = "postgres"
  engine_version       = "17.0"
  instance_class       = "db.m5.xlarge"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "main-db"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az             = false
  backup_retention_period = 1
  skip_final_snapshot  = true
  subnet_id            = aws_subnet.main.id
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
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

resource "aws_launch_template" "main" {
  name_prefix   = "main-lt-"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI ID
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "main-instance"
    }
  }
}

resource "aws_autoscaling_group" "main" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}

resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2.id]
  subnets            = [aws_subnet.main.id]
}

resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  alb_target_group_arn   = aws_lb_target_group.main.arn
}
```

This Terraform code creates the following resources based on the provided architecture diagram and configuration:

1. A VPC with one subnet
2. An RDS PostgreSQL instance with specified configuration
3. EC2 instances managed by an Auto Scaling Group
4. Security groups for RDS and EC2 instances
5. A launch template for EC2 instances
6. An Application Load Balancer with a target group and listener

Note that you may need to adjust some values, such as the AMI ID, to match your specific requirements and region.