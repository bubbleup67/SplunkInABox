provider "aws" {
  shared_credentials_file = "/Users/bubbleup/.aws/creds"
  profile                 = "johnraycool"
  region     = "${var.region}"
}

module "s3" {
    source = "/Users/bubbleup/git/SplunkInABox/Terraform/modules/s3"
    s3BucketName = "${var.s3BucketName}"
    projectTags = "${var.projectTags}"
    company = "${var.company}"
}

output "s3_id" {
    value = "${module.s3.id}"
}

resource "aws_sns_topic" "SplunkDelivery" {
  name = "SplunkDelivery"
}

resource "aws_cloudwatch_metric_alarm" "snsAlarm" {
  alarm_name                = "splunk-delivery-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "NumberOfMessagesPublished"
  namespace                 = "AWS/SNS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors SNS Activity"
  insufficient_data_actions = []
  dimensions {
     TopicName = "SplunkDelivery"
  }
}



resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "vpc-b81aacd0"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myIp}"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myIp}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "example" {
  ami           = "ami-f63b1193"
  instance_type = "t2.micro"
  key_name = "JR-East2"
  security_groups = ["${aws_security_group.allow_all.name}"]
  
  # Tells Terraform that this EC2 instance must be created only after the
  # S3 bucket has been created.
  # depends_on = ["aws_s3_bucket.example"]
  
  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt;echo ${module.s3.id} >> ip_address.txt"
  }
  
  provisioner "file" {
    source      = "/etc/hosts"
    destination = "/home/ec2-user/hosts.JR"

    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("/Users/bubbleup/.ssh/JR-East2.pem")}"
    }
  }
}
resource "aws_elb" "bar" {
  name               = "splunk-terraform-elb"
  availability_zones = ["us-east-2c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.example.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "splunk-terraform-elb"
  }
}
