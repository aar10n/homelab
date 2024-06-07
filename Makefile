MANIFEST_DIR = terraform/modules/k8s_cluster/manifests

FLANNEL_VERSION = 0.25.2
FLANNEL_FILE = flannel-$(subst .,_,$(FLANNEL_VERSION)).yaml
FLANNEL_URL = https://github.com/flannel-io/flannel/releases/download/v$(FLANNEL_VERSION)/kube-flannel.yml

METALLB_VERSION = 0.14.5
METALLB_FILE = metallb-native-$(subst .,_,$(METALLB_VERSION)).yaml
METALLB_URL = https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VERSION)/config/manifests/metallb-native.yaml

download-manifests: flannel-manifest metallb-manifest

%-manifest: varname = $(shell echo '$*' | tr '[:lower:]' '[:upper:]')
%-manifest:
	rm -f $(wildcard $(MANIFEST_DIR)/$**) || true
	wget -O $(MANIFEST_DIR)/$($(varname)_FILE) $($(varname)_URL)
