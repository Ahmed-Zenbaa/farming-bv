# IAM role / instance profile for SSM
resource "aws_iam_role" "ssm_role" {
    name               = "farming-bv-ssm-role"
    assume_role_policy = data.aws_iam_policy_document.ssm_assume_policy.json
}


data "aws_iam_policy_document" "ssm_assume_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
    role       = aws_iam_role.ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach inline S3 access policy
resource "aws_iam_role_policy" "s3_access" {
  name = "farming-bv-s3-access"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.nginx_assets.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ssm_profile" {
    name = "farming-bv-ssm-instance-profile"
    role = aws_iam_role.ssm_role.name
}


data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
    ami                         = data.aws_ami.amazon_linux_2023.id
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.private.id
    vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = false
    iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

    # ensure bucket & objects exist before instance creation
    depends_on = [
        aws_s3_object.nginx_conf,
        aws_s3_object.logo
    ]

    metadata_options {
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
    }


    user_data = <<-EOT
                #!/bin/bash
                yum update -y
                systemctl disable --now sshd
                if ! systemctl is-active amazon-ssm-agent >/dev/null 2>&1; then
                yum install -y amazon-ssm-agent
                systemctl enable --now amazon-ssm-agent
                fi

                yum install -y nginx
                systemctl enable --now nginx
                aws s3 cp s3://${aws_s3_bucket.nginx_assets.bucket}/nginx.conf /etc/nginx/nginx.conf
                aws s3 cp s3://${aws_s3_bucket.nginx_assets.bucket}/farming-bv.jpg /usr/share/nginx/html/farming-bv.jpg
                systemctl restart nginx
                systemctl disable --now sshd

                EOT

    tags = {
        Name = "farming-bv-app"
    }
}