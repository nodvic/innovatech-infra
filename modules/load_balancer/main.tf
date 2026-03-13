resource "aws_lb" "monitoring_lb" {
  name               = "innovatech-monitoring-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.lb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "innovatech-monitoring-lb"
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name     = "grafana-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/login"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.monitoring_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}