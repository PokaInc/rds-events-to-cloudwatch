SHELL := /usr/bin/env bash
OUT_DIR = dist
TEMPLATE_FILE=template.yml
CF_BUCKET=cloudformation-`aws sts get-caller-identity --output text --query 'Account'`-$(AWS_DEFAULT_REGION)
ENV=
STACK_NAME=rds-events-to-cloudwatch-$(ENV)

# Check if variable has been defined, otherwise print custom error message
check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

check-bucket:
	@aws s3api head-bucket --bucket $(CF_BUCKET) &> /dev/null || aws s3 mb s3://$(CF_BUCKET)

package: check-bucket
	@sam package --s3-bucket $(CF_BUCKET) --template-file $(TEMPLATE_FILE) --output-template-file $(OUT_DIR)/$(TEMPLATE_FILE)

lint-templates:
	@cfn-lint

deploy: package lint-templates
	$(call check_defined, ENV, Ex: make deploy ENV=dev)
	@sam deploy --template-file $(OUT_DIR)/$(TEMPLATE_FILE) --stack-name $(STACK_NAME) --parameter-overrides Environment=$(ENV) --capabilities CAPABILITY_IAM
