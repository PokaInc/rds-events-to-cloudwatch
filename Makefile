# Check if variable has been defined, otherwise print custom error message
check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

install:
	@npm install

deploy:
	$(call check_defined, ENV, Ex: make deploy ENV=dev)
	@ENVIRONMENT=$(ENV) ./node_modules/serverless/bin/serverless deploy
