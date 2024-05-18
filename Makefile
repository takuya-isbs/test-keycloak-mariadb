define get_val
	$(shell grep ^$(1)= common.sh | cut -d= -f 2 | tr -d '"')
endef

PROJECT = $(call get_val,PROJECT)
HOSTS =  $(call get_val,HOSTS)
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
	@for h in $(HOSTS); do \
           $(EXEC) $(PROJECT)-$$h /SHARE/mariadb-status.sh || echo "ERROR !!!!!"; done
