# Feel free to delete this file once all environments have updated their state

moved {
  from = module.setup.module.acs
  to   = module.acs
}

moved {
  from = module.setup.aws_ssm_parameter.some_secret
  to   = aws_ssm_parameter.some_secret
}

moved {
  from = module.setup.module.my_ecr
  to   = module.my_ecr
}

moved {
  from = module.setup.module.gha_role
  to   = module.gha_role
}
