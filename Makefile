MANIFEST_DIR = terraform/modules/k8s_cluster/manifests

FLANNEL_VERSION = 0.25.2
FLANNEL_FILE 	= flannel-cni.yaml
FLANNEL_URL 	= https://github.com/flannel-io/flannel/releases/download/v$(FLANNEL_VERSION)/kube-flannel.yml

METALLB_VERSION = 0.14.5
METALLB_FILE    = metallb-native.yaml
METALLB_URL  	= https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VERSION)/config/manifests/metallb-native.yaml

CONTOUR_VERSION = 1.29
CONTOUR_FILE 	= contour-gateway.yaml
CONTOUR_URL 	= https://raw.githubusercontent.com/projectcontour/contour/release-$(CONTOUR_VERSION)/examples/render/contour-gateway-provisioner.yaml

manifests = flannel-manifest \
			metallb-manifest \
			contour-manifest


download-manifests: $(manifests)


# ====== Manifest download rule ======
%-manifest: VAR = $(shell echo '$*' | tr '[:lower:]' '[:upper:]' | tr - _)
%-manifest:
	rm -f $(MANIFEST_DIR)/$($(VAR)_FILE)
	curl -L $($(VAR)_URL) | awk '!/^\s*#/ && NF' > $(MANIFEST_DIR)/$($(VAR)_FILE)

