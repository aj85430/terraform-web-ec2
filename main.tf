resource "aws_vpc" "web" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "web"
  }
}
resource "aws_subnet" "public" {
  count             = length(var.subnet_cidr)
  vpc_id            = aws_vpc.web.id
  cidr_block        = var.subnet_cidr[count.index]
  availability_zone = var.availability_zone[count.index]
  tags = {
    "Name" = "web-public-${count.index + 1}"
  }
}

resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.web.id
  tags = {
    "Name" = "web-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnet_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_internet_gateway" "web-igw" {
  vpc_id = aws_vpc.web.id
  tags = {
    "Name" = "web-gateway"
  }
}

resource "aws_route" "web-route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.web-rt.id
  gateway_id             = aws_internet_gateway.web-igw.id
}

resource "aws_security_group" "lb" {
  name        = "lb-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.web.id
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.web.id
}

resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web.id
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "web-attach" {
  count            = length(aws_instance.servers)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = element(aws_instance.servers.*.id, count.index)
  port             = 80
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb" "web" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  enable_deletion_protection = false
  tags = {
    Environment = "web"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "servers" {
  count                  = length(var.subnet_cidr)
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.amazon_linux.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = element(aws_subnet.public.*.id, count.index)
  associate_public_ip_address = true
  tags = {
    Name = "web-server-${count.index + 1}"
  }
  user_data = file("data/data.tpl")
}
