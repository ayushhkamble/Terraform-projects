resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.security_group_id]
  subnets         = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.alb_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}