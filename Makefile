SHELL := /bin/bash
COMMON := $(realpath common.sh)

define get_val
$(shell DEBUG=0 . $(COMMON); echo $$$(1) )
endef

PROJECT = $(call get_val,PROJECT)
HOSTS =  $(call get_val,HOSTS)
DB_HOSTS =  $(call get_val,DB_HOSTS)
LXC := $(call get_val,LXC)
EXEC = $(LXC) exec --cwd /SHARE

define gen_target
       $(foreach name,$(HOSTS),$(1)@$(name))
endef

TARGET_SHELL = $(call gen_target,shell)
.PONY: $(TARGET_SHELL)
$(TARGET_SHELL): shell@%:
	$(EXEC) $(PROJECT)-$* bash

.PONY: mariadb-status
mariadb-status:
	@for h in $(DB_HOSTS); do \
           $(EXEC) $(PROJECT)-$$h /SHARE/mariadb-status.sh || echo "ERROR !!!!!"; done

.PONY: mariadb-bootstrap
mariadb-bootstrap:
	@for h in $(DB_HOSTS); do \
           echo "------- $$h --------";\
           $(EXEC) --cwd /SHARE $(PROJECT)-$$h ./mariadb-show-bootstrap.sh; done

.PONY: ps
ps:
	@for h in $(HOSTS); do \
           echo "------- $$h --------";\
           $(EXEC) $(PROJECT)-$$h docker compose ps; done

.PONY: restart-keepalived-loop
restart-keepalived-loop:
	bash restart-keepalived-loop.sh

.PONY: health-check
health-check:
	bash health-check.sh
