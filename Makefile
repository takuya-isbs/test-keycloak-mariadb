PROJECT = testkc
HOSTS = kc1 kc2 kc3
EXEC = lxc exec --cwd /SHARE

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
