# ALB security group: allow HTTPS from anywhere
resource "aws_security_group" "alb_sg" {
    name        = "farming-bv-alb-sg"
    description = "Allow inbound HTTPS from internet"
    vpc_id      = aws_vpc.main.id

    ingress {
        description = "HTTP from internet"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS from internet"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }


    tags = { Name = "farming-bv-alb-sg" }
}


# EC2 security group: only allow traffic from ALB SG
resource "aws_security_group" "ec2_sg" {
    name        = "farming-bv-ec2-sg"
    description = "Allow traffic from ALB only"
    vpc_id      = aws_vpc.main.id


    ingress {
        description     = "Allow HTTP from ALB"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }


    tags = { Name = "farming-bv-ec2-sg" }
}