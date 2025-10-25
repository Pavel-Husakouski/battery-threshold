# Battery threshold system deployment
INSTALL_DIR = /etc/systemd/system

.PHONY: install uninstall copy start stop status log last

install: copy start

copy:
	sudo cp battery-threshold.sh $(INSTALL_DIR)/ && sudo chmod +x $(INSTALL_DIR)/battery-threshold.sh
	sudo cp battery-threshold.{service,timer} $(INSTALL_DIR)/

start:
	sudo systemctl daemon-reload
	sudo systemctl enable --now battery-threshold.timer

stop:
	sudo systemctl disable --now battery-threshold.timer

uninstall:
	sudo systemctl disable --now battery-threshold.timer || true
	sudo rm -f $(INSTALL_DIR)/battery-threshold.{sh,service,timer}
	sudo systemctl daemon-reload

status:
	sudo systemctl status battery-threshold.timer --no-pager

log:
	sudo journalctl -u battery-threshold.service --no-pager -f

last:
	sudo journalctl -u battery-threshold.service --no-pager -n 10 --since "24 hours ago"
