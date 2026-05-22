# 1. Launch Configuration 대신 Launch Template 사용
resource "aws_launch_template" "as_template" {
  name_prefix   = "terraform-lt-backend-"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t3.micro"
  key_name      = "history"

  # Launch Template에서는 security_groups 대신 vpc_security_group_ids를 사용합니다.
  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  # User Data는 base64encode 처리를 해주는 것이 안전합니다.
  # EOF/EOT 불일치 오류와 중괄호 위치를 수정했습니다.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    cat > /var/www/html/index.nginx-debian.html <<'HTML'
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>history-cloud.store</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, "Segoe UI", Roboto, sans-serif;
          background: #0a0a0f;
          color: #e4e4e7;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
        }
        .bg {
          position: fixed; inset: 0;
          background:
            radial-gradient(600px circle at 20% 30%, rgba(99,102,241,0.15), transparent),
            radial-gradient(800px circle at 80% 70%, rgba(168,85,247,0.12), transparent);
        }
        .card {
          position: relative;
          text-align: center;
          padding: 60px 50px;
          max-width: 560px;
        }
        .badge {
          display: inline-block;
          padding: 6px 16px;
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 100px;
          font-size: 13px;
          color: #a1a1aa;
          margin-bottom: 28px;
        }
        .badge span { color: #818cf8; }
        h1 {
          font-size: 52px;
          font-weight: 800;
          line-height: 1.1;
          margin-bottom: 20px;
          background: linear-gradient(135deg, #fff 0%, #a5b4fc 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        p.sub {
          font-size: 18px;
          color: #a1a1aa;
          line-height: 1.6;
          margin-bottom: 36px;
        }
        .info {
          display: flex;
          gap: 12px;
          justify-content: center;
          flex-wrap: wrap;
        }
        .chip {
          padding: 10px 18px;
          background: rgba(255,255,255,0.04);
          border: 1px solid rgba(255,255,255,0.08);
          border-radius: 12px;
          font-size: 14px;
          color: #d4d4d8;
        }
        .chip b { color: #818cf8; }
        .footer {
          margin-top: 40px;
          font-size: 13px;
          color: #52525b;
        }
      </style>
    </head>
    <body>
      <div class="bg"></div>
      <div class="card">
        <div class="badge">🚀 <span>Deployed with Terraform</span></div>
        <h1>history-cloud.store</h1>
        <p class="sub">AWS 위에 Terraform으로 구축한 인프라입니다.<br>VPC부터 ALB, Auto Scaling까지 코드로 배포되었습니다.</p>
        <div class="info">
          <div class="chip">⚙️ <b>ALB</b> + Auto Scaling</div>
          <div class="chip">🌏 <b>ap-northeast-2</b></div>
          <div class="chip">📦 <b>nginx</b> on EC2</div>
        </div>
        <div class="footer">Infrastructure as Code · 2026</div>
      </div>
    </body>
    </html>
    HTML
  EOF
  )

  # Launch Template의 태그 지정 방식
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "jeff-userdata"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Auto-Scaling 그룹 생성 (수정된 Launch Template 참조)
resource "aws_autoscaling_group" "terraform-prd-asg" {
  name                      = "terraform-prd-asg"
  vpc_zone_identifier       = [aws_subnet.terraform-pub-subnet-2a.id, aws_subnet.terraform-pub-subnet-2c.id]
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 3
  health_check_grace_period = 120
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.terraform-prd-tg.arn]

  # 기존 launch_configuration 지우고 launch_template 추가
  launch_template {
    id      = aws_launch_template.as_template.id
    version = "$Latest" # 언제나 최신 버전의 템플릿 적용
  }

  lifecycle {
    create_before_destroy = true
  }
}

