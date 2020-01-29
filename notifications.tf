# sms only available in us-east-1 and us-west-2

# swarm notifications
# resource "aws_sns_topic" "swarm_updates" {
#   name = format("%s-%s-topic",var.environment,var.namespace)
#   display_name = format("%s-%s",var.environment,var.namespace)
#   delivery_policy = <<EOF
# {
#   "http": {
#     "defaultHealthyRetryPolicy": {
#       "minDelayTarget": 20,
#       "maxDelayTarget": 20,
#       "numRetries": 3,
#       "numMaxDelayRetries": 0,
#       "numNoDelayRetries": 0,
#       "numMinDelayRetries": 0,
#       "backoffFunction": "linear"
#     },
#     "disableSubscriptionOverrides": false,
#     "defaultThrottlePolicy": {
#       "maxReceivesPerSecond": 1
#     }
#   }
# }
# EOF
# }

# resource "aws_sns_topic_subscription" "subscription" {
#   count     = length(var.subscriptions)
#   topic_arn = aws_sns_topic.swarm_updates.arn
#   protocol  = "sms"
#   endpoint  = element(var.subscriptions, count.index)
# }
