

resource "aws_acm_certificate" "farming_bv" {
  private_key      = file("${path.module}/../certs/farming-bv.local.key")
  certificate_body = file("${path.module}/../certs/farming-bv.local.crt")
}



resource "aws_lb" "app" {
  name                       = "farming-bv-alb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  enable_deletion_protection = false
  tags = {
    Name = "farming-bv-alb"
  }
}


resource "aws_lb_target_group" "tg" {
    name     = "farming-bv-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id
    health_check {
        path                = "/"
        protocol            = "HTTP"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        interval            = 30
    }
    tags = { Name = "farming-bv-tg" }
}

# HTTP Listener (port 80) - redirects to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.app.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn   = aws_acm_certificate.farming_bv.arn
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}


resource "aws_lb_target_group_attachment" "app_att" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id        = aws_instance.app.id
    port             = 80
}
