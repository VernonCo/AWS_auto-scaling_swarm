# create scale up and down policies for masters and workers auto-scaling groups
# scale up alarm
resource "aws_autoscaling_policy" "hi-cpu-masters-policy" {
	name = format("%s-%s-hi-cpu-masters-policy",var.environment,var.namespace)
	autoscaling_group_name = aws_autoscaling_group.masters.name
	adjustment_type = "ChangeInCapacity"
	scaling_adjustment = "1"
	cooldown = "300"
	policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "hi-cpu-masters-alarm" {
	alarm_name = format("%s-%s-hi-cpu-masters-alarm",var.environment,var.namespace)
	alarm_description = "hi-cpu-alarm"
	comparison_operator = "GreaterThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	statistic = "Average"
	threshold = "60"
	dimensions = {
		"AutoScalingGroupName" = aws_autoscaling_group.masters.name
	}
	actions_enabled = true
	alarm_actions = [aws_autoscaling_policy.hi-cpu-masters-policy.arn]
}


# scale down alarm
resource "aws_autoscaling_policy" "low-cpu-masters-policy-scaledown" {
	name = format("%s-%s-low-cpu-masters-policy",var.environment,var.namespace)
	autoscaling_group_name = aws_autoscaling_group.masters.name
	adjustment_type = "ChangeInCapacity"
	scaling_adjustment = "-1"
	cooldown = "300"
	policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "low-cpu-masters-alarm-scaledown" {
	alarm_name = format("%s-%s-low-cpu-masters-alarm",var.environment,var.namespace)
	alarm_description = "low-cpu-alarm-scaledown"
	comparison_operator = "LessThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	statistic = "Average"
	threshold = "50"
	dimensions = {
		"AutoScalingGroupName" = aws_autoscaling_group.masters.name
	}
	actions_enabled = true
	alarm_actions = [aws_autoscaling_policy.low-cpu-masters-policy-scaledown.arn]
}

# scale up alarm
resource "aws_autoscaling_policy" "hi-cpu-workers-policy" {
	name = format("%s-%s-hi-cpu-workers-policy",var.environment,var.namespace)
	autoscaling_group_name = aws_autoscaling_group.workers.name
	adjustment_type = "ChangeInCapacity"
	scaling_adjustment = "1"
	cooldown = "300"
	policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "hi-cpu-workers-alarm" {
	alarm_name = format("%s-%s-hi-cpu-workers-alarm",var.environment,var.namespace)
	alarm_description = "hi-cpu-alarm"
	comparison_operator = "GreaterThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	statistic = "Average"
	threshold = "60"
	dimensions = {
		"AutoScalingGroupName" = aws_autoscaling_group.workers.name
	}
	actions_enabled = true
	alarm_actions = [aws_autoscaling_policy.hi-cpu-workers-policy.arn]
}


# scale down alarm
resource "aws_autoscaling_policy" "low-cpu-workers-policy-scaledown" {
	name = format("%s-%s-low-cpu-workers-policy",var.environment,var.namespace)
	autoscaling_group_name = aws_autoscaling_group.workers.name
	adjustment_type = "ChangeInCapacity"
	scaling_adjustment = "-1"
	cooldown = "300"
	policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "low-cpu-workers-alarm-scaledown" {
	alarm_name = format("%s-%s-low-cpu-workers-alarm",var.environment,var.namespace)
	alarm_description = "low-cpu-alarm-scaledown"
	comparison_operator = "LessThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	statistic = "Average"
	threshold = "50"
	dimensions = {
		"AutoScalingGroupName" = aws_autoscaling_group.workers.name
	}
	actions_enabled = true
	alarm_actions = [aws_autoscaling_policy.low-cpu-workers-policy-scaledown.arn]
}
