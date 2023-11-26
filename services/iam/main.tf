resource "aws_iam_group_policy" "my_developer_policy" {
  name  = "my_developer_policy"
  group = aws_iam_group.my_developers.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "NotAction" : [
          "iam:*",
          "organizations:*",
          "account:*"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:ListRoles",
          "organizations:DescribeOrganization",
          "account:ListRegions",
          "account:GetAccountInformation"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_group" "my_developers" {
  name = "developers"
}


resource "aws_iam_user" "lb" {
  name = "test-user"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_user_group_membership" "developers" {
  user = aws_iam_user.lb.name

  groups = [
    aws_iam_group.my_developers.name,
  ]
}
